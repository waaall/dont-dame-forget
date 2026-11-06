package com.dontforget.dont_forget;

import static org.junit.Assert.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import android.app.AlarmManager;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.media.AudioManager;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;
import android.util.Log;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.Map;
import kotlin.jvm.functions.Function0;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.mockito.MockedConstruction;
import org.mockito.MockedStatic;

/** Exercise real engine transitions with failing Android scheduling and a transactional store. */
public class ReminderEngineRecoveryTest {
    private final ArrayList<AutoCloseable> mocks = new ArrayList<>();
    private final Map<String, JSONObject> plans = new LinkedHashMap<>();
    private final Map<String, JSONObject> occurrences = new LinkedHashMap<>();
    private Context context;
    private AlarmManager alarms;
    private NotificationManager notifications;
    private ReminderEngine engine;
    private ReminderStore store;
    private MockedConstruction<Handler> handlers;
    private RuntimeException commitFailure;
    private long scheduledAt;
    private long pendingAt;

    private <T extends AutoCloseable> T track(T mock) { mocks.add(mock); return mock; }
    private static JSONObject copy(JSONObject value) {
        try { return value == null ? null : new JSONObject(value.toString()); }
        catch (JSONException error) { throw new AssertionError(error); }
    }
    private static Map<String, JSONObject> copies(Map<String, JSONObject> values) {
        Map<String, JSONObject> result = new LinkedHashMap<>();
        values.forEach((id, value) -> result.put(id, copy(value)));
        return result;
    }
    private static void staticField(Class<?> owner, String name, Object value) throws Exception {
        Field field = owner.getDeclaredField(name);
        field.setAccessible(true);
        field.set(null, value);
    }

    @Before public void setUp() throws Exception {
        context = mock(Context.class);
        alarms = mock(AlarmManager.class);
        notifications = mock(NotificationManager.class);
        when(context.createDeviceProtectedStorageContext()).thenReturn(context);
        when(context.getSharedPreferences(anyString(), anyInt())).thenReturn(mock(SharedPreferences.class));
        when(context.getSystemService(AlarmManager.class)).thenReturn(alarms);
        when(context.getSystemService(NotificationManager.class)).thenReturn(notifications);
        when(context.getSystemService(AudioManager.class)).thenReturn(mock(AudioManager.class));
        when(context.getSystemService(PowerManager.class)).thenReturn(mock(PowerManager.class));
        when(notifications.areNotificationsEnabled()).thenReturn(false);
        when(alarms.canScheduleExactAlarms()).thenReturn(true);
        handlers = track(mockConstruction(Handler.class));
        track(mockStatic(Looper.class));
        track(mockStatic(Log.class));
        track(mockConstruction(AlarmManager.AlarmClockInfo.class, (info, construction) ->
            when(info.getTriggerTime()).thenReturn((Long) construction.arguments().get(0))));
        doAnswer(call -> {
            scheduledAt = ((AlarmManager.AlarmClockInfo) call.getArgument(0)).getTriggerTime();
            return null;
        }).when(alarms).setAlarmClock(any(), any());
        track(mockConstruction(Intent.class, (intent, construction) -> {
            when(intent.setAction(anyString())).thenReturn(intent);
            when(intent.setData(any())).thenReturn(intent);
            when(intent.putExtra(anyString(), anyString())).thenReturn(intent);
            when(intent.putExtra(anyString(), anyLong())).thenAnswer(call -> {
                String key = call.getArgument(0);
                long value = call.getArgument(1);
                when(intent.getLongExtra(eq(key), anyLong())).thenReturn(value);
                return intent;
            });
        }));
        MockedStatic<Uri> uris = track(mockStatic(Uri.class));
        Uri uri = mock(Uri.class);
        uris.when(() -> Uri.parse(anyString())).thenReturn(uri);
        MockedStatic<PendingIntent> pending = track(mockStatic(PendingIntent.class));
        PendingIntent operation = mock(PendingIntent.class);
        pending.when(() -> PendingIntent.getActivity(any(), anyInt(), any(), anyInt())).thenReturn(operation);
        pending.when(() -> PendingIntent.getBroadcast(any(), anyInt(), any(), anyInt())).thenAnswer(call -> {
            pendingAt = ((Intent) call.getArgument(2)).getLongExtra("at", 0);
            return operation;
        });
        track(mockConstruction(PasswordVault.class, (vault, construction) -> {
            when(vault.configured()).thenReturn(true);
            when(vault.matches(anyString())).thenReturn(true);
        }));
        track(mockConstruction(ReminderStore.class, (store, construction) -> {
            this.store = store;
            when(store.plan(anyString())).thenAnswer(call -> copy(plans.get(call.getArgument(0))));
            when(store.occurrence(anyString())).thenAnswer(call -> copy(occurrences.get(call.getArgument(0))));
            when(store.live()).thenAnswer(call -> {
                ArrayList<JSONObject> live = new ArrayList<>();
                occurrences.values().stream()
                    .filter(item -> ReminderPolicy.INSTANCE.getLiveStates().contains(item.optString("status")))
                    .forEach(item -> live.add(copy(item)));
                return live;
            });
            doAnswer(call -> {
                JSONObject plan = call.getArgument(0);
                plans.put(plan.getString("id"), copy(plan));
                return null;
            }).when(store).putPlan(any());
            doAnswer(call -> {
                JSONObject item = call.getArgument(0);
                occurrences.put(item.getString("id"), copy(item));
                return null;
            }).when(store).putOccurrence(any());
            when(store.transaction(any())).thenAnswer(call -> {
                Map<String, JSONObject> savedPlans = copies(plans), savedOccurrences = copies(occurrences);
                try {
                    Object result = ((Function0<?>) call.getArgument(0)).invoke();
                    if (commitFailure != null) throw commitFailure;
                    return result;
                }
                catch (Throwable failure) {
                    plans.clear(); plans.putAll(savedPlans);
                    occurrences.clear(); occurrences.putAll(savedOccurrences);
                    throw failure;
                }
            });
        }));
        Constructor<ReminderEngine> constructor = ReminderEngine.class.getDeclaredConstructor(Context.class);
        constructor.setAccessible(true);
        engine = constructor.newInstance(context);
        // A running service lets the test observe the engine's playback refresh request.
        staticField(AlarmService.class, "running", mock(AlarmService.class));
    }

    @After public void tearDown() throws Exception {
        staticField(AlarmService.class, "running", null);
        for (int i = mocks.size() - 1; i >= 0; i--) mocks.get(i).close();
    }

    private void seed(boolean repeating, boolean review, String status, long at) throws JSONException {
        JSONObject plan = new JSONObject().put("id", "plan").put("title", "Reminder")
            .put("category", "alarm").put("enabled", true).put("repeating", repeating)
            .put("date", LocalDate.now().toString()).put("hour", 7).put("minute", 0)
            .put("days", new JSONArray(new int[]{1, 2, 3, 4, 5, 6, 7}))
            .put("mission", "math").put("difficulty", "easy").put("mathCount", 1)
            .put("reviewEnabled", review).put("reviewMinutes", 10);
        plans.put("plan", copy(plan));
        occurrences.put("occurrence", new JSONObject().put("id", "occurrence").put("planId", "plan")
            .put("plan", copy(plan)).put("status", status).put("nextAt", at).put("originalAt", at)
            .put("isReview", false).put("mathDone", 0).put("snoozeCount", 0)
            .put("question", "7 + 5").put("answer", 12).put("questionToken", "token"));
    }

    @Test public void disabledNotificationsDoNotPreventAnExistingAlarmFromSnoozing() throws Exception {
        seed(false, false, "ringing", System.currentTimeMillis() - 1000);
        engine.snooze("occurrence", 10);
        assertEquals("snoozed", occurrences.get("occurrence").getString("status"));
        verify(alarms).setAlarmClock(any(), any());
        verify(context).startService(any());
    }

    @Test public void failedSnoozePreservesTheRingingMissionAndItsQuestion() throws Exception {
        seed(false, false, "ringing", System.currentTimeMillis() - 1000);
        doThrow(new SecurityException("Scheduling rejected")).when(alarms).setAlarmClock(any(), any());
        assertThrows(SecurityException.class, () -> engine.snooze("occurrence", 10));
        JSONObject current = occurrences.get("occurrence");
        assertEquals("ringing", current.getString("status"));
        assertEquals("token", current.getString("questionToken"));
        assertEquals(0, current.getInt("snoozeCount"));
        verify(context, never()).startService(any());
    }

    @Test public void failedSnoozeCommitRestoresThePreviousSystemAlarmAndMission() throws Exception {
        long previousAt = System.currentTimeMillis() + 60_000;
        seed(false, false, "snoozed", previousAt);
        occurrences.get("occurrence").getJSONObject("plan").put("mathCount", 3);
        occurrences.get("occurrence").put("mathDone", 1).put("snoozeCount", 2);
        String previous = occurrences.get("occurrence").toString();
        engine.repairScheduled();
        clearInvocations(alarms);
        commitFailure = new IllegalStateException("SQLite commit failed");

        assertSame(commitFailure, assertThrows(IllegalStateException.class, () -> engine.snooze("occurrence", 10)));

        assertEquals(previous, occurrences.get("occurrence").toString());
        assertEquals(previousAt, scheduledAt);
        assertEquals(previousAt, pendingAt);
        verify(alarms, times(2)).setAlarmClock(any(), any());
        verify(context, never()).startService(any());
        verify(handlers.constructed().get(0), never()).post(any());
    }

    @Test public void rejectedSnoozeRestoresThePendingIntentOfAnExistingAlarm() throws Exception {
        long previousAt = System.currentTimeMillis() + 60_000;
        seed(false, false, "snoozed", previousAt);
        engine.repairScheduled();
        SecurityException failure = new SecurityException("Scheduling rejected");
        doThrow(failure).doAnswer(call -> {
            scheduledAt = ((AlarmManager.AlarmClockInfo) call.getArgument(0)).getTriggerTime();
            return null;
        }).when(alarms).setAlarmClock(any(), any());

        assertSame(failure, assertThrows(SecurityException.class, () -> engine.snooze("occurrence", 10)));

        assertEquals(previousAt, occurrences.get("occurrence").getLong("nextAt"));
        assertEquals(previousAt, scheduledAt);
        assertEquals(previousAt, pendingAt);
    }

    @Test public void failedAlarmRestorationKeepsTheCommitErrorAndAllowsForegroundRecovery() throws Exception {
        long previousAt = System.currentTimeMillis() + 60_000;
        seed(false, false, "snoozed", previousAt);
        commitFailure = new IllegalStateException("SQLite commit failed");
        SecurityException restoreFailure = new SecurityException("Restoring rejected");
        doAnswer(call -> {
            scheduledAt = ((AlarmManager.AlarmClockInfo) call.getArgument(0)).getTriggerTime();
            return null;
        }).doThrow(restoreFailure).when(alarms).setAlarmClock(any(), any());

        assertSame(commitFailure, assertThrows(IllegalStateException.class, () -> engine.snooze("occurrence", 10)));
        assertArrayEquals(new Throwable[]{restoreFailure}, commitFailure.getSuppressed());
        assertEquals(previousAt, occurrences.get("occurrence").getLong("nextAt"));
        assertEquals("token", occurrences.get("occurrence").getString("questionToken"));
        verify(context, never()).startService(any());

        doAnswer(call -> {
            scheduledAt = ((AlarmManager.AlarmClockInfo) call.getArgument(0)).getTriggerTime();
            return null;
        }).when(alarms).setAlarmClock(any(), any());
        engine.repairScheduled();
        assertEquals(previousAt, scheduledAt);
        assertEquals(previousAt, pendingAt);
    }

    @Test public void failedWriteBeforeSchedulingLeavesThePreviousSystemAlarmUntouched() throws Exception {
        long previousAt = System.currentTimeMillis() + 60_000;
        seed(false, false, "snoozed", previousAt);
        engine.repairScheduled();
        clearInvocations(alarms);
        IllegalStateException failure = new IllegalStateException("SQLite write failed");
        doThrow(failure).when(store).putOccurrence(any());

        assertSame(failure, assertThrows(IllegalStateException.class, () -> engine.snooze("occurrence", 10)));

        verify(alarms, never()).setAlarmClock(any(), any());
        assertEquals(previousAt, scheduledAt);
        assertEquals(previousAt, pendingAt);
        assertEquals("snoozed", occurrences.get("occurrence").getString("status"));
    }

    @Test public void reviewSchedulingFailureStillCompletesTheCurrentMissionAndRefreshesAudio() throws Exception {
        long originalAt = System.currentTimeMillis() - 1000;
        seed(false, true, "ringing", originalAt);
        doThrow(new SecurityException("Exact access revoked")).when(alarms).setAlarmClock(any(), any());
        assertTrue(engine.answer("occurrence", "12", "token").getBoolean("completed"));
        assertEquals("reviewPending", occurrences.get("occurrence").getString("status"));
        verify(context).startService(any());
        verify(handlers.constructed().get(0)).post(any());
        clearInvocations(alarms);
        doNothing().when(alarms).setAlarmClock(any(), any());
        engine.repairScheduled();
        verify(alarms).setAlarmClock(any(), any());
        assertFalse(engine.fire("occurrence", originalAt));
    }

    @Test public void repeatingCompletionSurvivesASystemSchedulingErrorAndCanRecover() throws Exception {
        seed(true, false, "ringing", System.currentTimeMillis() - 1000);
        doThrow(new IllegalStateException("System unavailable")).when(alarms).setAlarmClock(any(), any());
        assertTrue(engine.answer("occurrence", "12", "token").getBoolean("completed"));
        assertEquals("completed", occurrences.get("occurrence").getString("status"));
        assertEquals(2, occurrences.size());
        verify(context).startService(any());
        doNothing().when(alarms).setAlarmClock(any(), any());
        clearInvocations(alarms);
        engine.repairScheduled();
        verify(alarms).setAlarmClock(any(), any());
    }

    @Test public void emergencyCompletionSurvivesFailureToScheduleTheNextRepeat() throws Exception {
        seed(true, true, "ringing", System.currentTimeMillis() - 1000);
        doThrow(new SecurityException("Exact access revoked")).when(alarms).setAlarmClock(any(), any());
        engine.emergency("occurrence", ReminderPolicy.OATH, "password");
        assertEquals("skipped", occurrences.get("occurrence").getString("status"));
        assertEquals(2, occurrences.size());
        verify(context).startService(any());
    }

    @Test public void clockRecoveryDoesNotSkipAnOverdueRepeat() throws Exception {
        long due = System.currentTimeMillis() - 60_000;
        seed(true, false, "scheduled", due);
        engine.reconcile(true);
        assertEquals(due, occurrences.get("occurrence").getLong("nextAt"));
        assertTrue(engine.fire("occurrence", due));
    }
}
