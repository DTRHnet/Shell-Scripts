# RoomManager: Enhanced Room-Capacity Guard & Assignment Layer

**Version**: 2.0  
**Date**: 2025-11-30  
**Status**: Production Ready

---

## Executive Summary

RoomManager is a robust room-capacity guard and assignment layer designed to prevent overbooking in clinic scheduling workflows. It integrates with Jane App (or simulated Jane data) to ensure that appointments never exceed available room capacity, while respecting practitioner-room preferences.

### Key Features

- ✅ **Capacity Enforcement**: Never allows more simultaneous appointments than available rooms
- ✅ **Atomic Booking Operations**: Race-condition-safe concurrent booking support
- ✅ **Practitioner-Room Preferences**: Assigns preferred rooms when available, falls back to any free room
- ✅ **Comprehensive Logging**: Full audit trail of all bookings, assignments, and conflicts
- ✅ **Concurrent Booking Support**: Handles simultaneous booking attempts safely
- ✅ **Test Suite**: Comprehensive automated tests covering all edge cases

---

## Architecture Overview

### Core Components

1. **RoomManager** (`backend/room_manager.py`)
   - Main room assignment logic
   - Capacity checking
   - Practitioner preference handling
   - Atomic booking operations

2. **RoomAssignment** (`backend/room_assignment.py`)
   - Low-level room finding algorithms
   - Locking mechanisms
   - Assignment record management

3. **Database Schema**
   - `rooms`: Room definitions
   - `appointments_cache`: Cached appointments from Jane
   - `assignments`: Room-to-appointment mappings
   - `practitioner_room_preferences`: Practitioner preferences
   - `events_log`: Audit trail

### Data Flow

```
Jane App (or Simulated Data)
    ↓
Webhook/Polling → Appointment Created
    ↓
RoomManager.assign_room()
    ↓
1. Acquire Lock (atomic)
2. Check Capacity
3. Find Best Room (respect preferences)
4. Create Assignment
5. Log Event
6. Release Lock
    ↓
Assignment Result → Jane App (notes update)
```

---

## API Reference

### RoomManager Class

#### `get_available_rooms(time_slot_start, time_slot_end, buffer_minutes=0)`

Get list of available rooms for a time slot.

**Parameters:**
- `time_slot_start` (datetime): Start of time slot
- `time_slot_end` (datetime): End of time slot
- `buffer_minutes` (int): Buffer time between appointments (default: 0)

**Returns:** List of available room dictionaries

**Example:**
```python
from room_manager import RoomManager
from datetime import datetime, timezone

manager = RoomManager("clinic-001")
start = datetime(2025, 12, 1, 10, 0, tzinfo=timezone.utc)
end = datetime(2025, 12, 1, 11, 0, tzinfo=timezone.utc)

available = await manager.get_available_rooms(start, end)
# Returns: [{"id": "...", "name": "Room A", ...}, ...]
```

#### `check_capacity(time_slot_start, time_slot_end, buffer_minutes=0)`

Check if there is capacity for a new appointment.

**Parameters:**
- `time_slot_start` (datetime): Start of time slot
- `time_slot_end` (datetime): End of time slot
- `buffer_minutes` (int): Buffer time between appointments

**Returns:** Tuple of `(has_capacity, total_rooms, occupied_rooms)`

**Example:**
```python
has_capacity, total, occupied = await manager.check_capacity(start, end)
if not has_capacity:
    print(f"No capacity: {occupied}/{total} rooms occupied")
```

#### `assign_room(practitioner_id, appointment_id, appointment_start, appointment_end, ...)`

Atomically assign a room to an appointment.

**Parameters:**
- `practitioner_id` (str): Jane practitioner ID
- `appointment_id` (str): Appointment ID
- `appointment_start` (datetime): Appointment start time
- `appointment_end` (datetime): Appointment end time
- `assigned_by` (str): Who is making the assignment (default: "system")
- `source` (str): Source of assignment (default: "api")
- `buffer_minutes` (int): Buffer time between appointments (default: 0)
- `allow_preferred_fallback` (bool): If preferred unavailable, use any free room (default: True)

**Returns:** Dictionary with assignment result:
```python
{
    "success": bool,
    "room_id": str | None,
    "room_name": str | None,
    "action": str,  # "assigned", "rejected", "waitlisted"
    "reason": str | None,
    "preferred_room_used": bool,
    "capacity_info": {
        "total": int,
        "occupied": int,
        "available": int
    },
    "assignment_id": str | None
}
```

**Example:**
```python
result = await manager.assign_room(
    practitioner_id="practitioner-123",
    appointment_id="apt-456",
    appointment_start=start,
    appointment_end=end,
    assigned_by="admin",
    source="webhook"
)

if result["success"]:
    print(f"Assigned {result['room_name']} to appointment")
    if result["preferred_room_used"]:
        print("Used practitioner's preferred room")
else:
    print(f"Rejected: {result['reason']}")
```

#### `release_room(appointment_id, actor="system")`

Release a room assignment (e.g., on cancellation).

**Parameters:**
- `appointment_id` (str): Appointment ID
- `actor` (str): Who is releasing the room (default: "system")

**Returns:** Dictionary with release result

**Example:**
```python
result = await manager.release_room("apt-456", actor="admin")
if result["success"]:
    print(f"Released {result['room_name']}")
```

#### `simulate_concurrent_booking(requests)`

Simulate concurrent booking attempts (useful for testing).

**Parameters:**
- `requests` (List[Dict]): List of booking requests

**Returns:** List of assignment results

**Example:**
```python
requests = [
    {
        "appointment_id": "apt-1",
        "practitioner_id": "practitioner-1",
        "start": datetime(...),
        "end": datetime(...),
        "assigned_by": "test",
        "source": "simulation"
    },
    # ... more requests
]

results = await manager.simulate_concurrent_booking(requests)
successful = [r for r in results if r["success"]]
print(f"{len(successful)}/{len(results)} bookings succeeded")
```

---

## Practitioner-Room Preferences

### Setting Preferences

Use the preferences API to set practitioner-room preferences:

```python
POST /admin/preferences/practitioner-room
{
    "clinic_id": "clinic-001",
    "practitioner_id": "practitioner-123",
    "room_id": "room-uuid",
    "priority": 1  # 1 = preferred, 2 = acceptable, 3 = avoid
}
```

### How Preferences Work

1. **Preferred Room Available**: Assigns preferred room
2. **Preferred Room Occupied**: Falls back to any available room (if `allow_preferred_fallback=True`)
3. **No Preference Set**: Uses standard room assignment algorithm (minimum overlaps)

### Priority Levels

- **Priority 1**: Preferred room (highest priority)
- **Priority 2**: Acceptable room
- **Priority 3**: Avoid room (not currently used, reserved for future)

---

## Capacity Enforcement

### How It Works

1. **Pre-Booking Check**: Before assignment, checks if `occupied_rooms < total_rooms`
2. **Atomic Operation**: Check and assignment happen inside a database lock
3. **Rejection**: If capacity exceeded, booking is rejected with clear error message

### Capacity Calculation

- **Total Rooms**: Count of active, non-blocked rooms at appointment time
- **Occupied Rooms**: Count of distinct rooms with overlapping appointments
- **Available**: `total_rooms - occupied_rooms`

### Example Scenarios

**Scenario 1: Capacity Available**
- 3 rooms total
- 2 rooms occupied
- New booking → ✅ Allowed (2 < 3)

**Scenario 2: Capacity Exceeded**
- 3 rooms total
- 3 rooms occupied
- New booking → ❌ Rejected (3 >= 3)

**Scenario 3: Concurrent Bookings**
- 3 rooms total
- 2 rooms occupied
- 2 simultaneous booking requests
- Result: Only 1 succeeds (atomic lock ensures this)

---

## Logging & Audit Trail

### Event Types

All events are logged to `events_log` table:

- `BOOKING_SUCCESS`: Room successfully assigned
- `BOOKING_REJECTED`: Booking rejected (capacity exceeded)
- `ROOM_ASSIGNED`: Room assignment created
- `ROOM_RELEASED`: Room assignment removed
- `PREFERENCE_CREATED`: Practitioner-room preference set
- `PREFERENCE_DELETED`: Practitioner-room preference removed

### Logging Format

```python
{
    "clinic_id": "clinic-001",
    "event_type": "BOOKING_SUCCESS",
    "appointment_id": "apt-456",
    "actor": "system",
    "details": {
        "room_id": "room-uuid",
        "room_name": "Room A",
        "practitioner_id": "practitioner-123",
        "preferred_room_used": true,
        "source": "webhook",
        "time_slot": {
            "start": "2025-12-01T10:00:00Z",
            "end": "2025-12-01T11:00:00Z"
        }
    },
    "created_at": "2025-12-01T10:00:00Z"
}
```

### Querying Logs

```sql
-- Get all booking events for a clinic
SELECT * FROM events_log
WHERE clinic_id = 'clinic-001'
AND event_type IN ('BOOKING_SUCCESS', 'BOOKING_REJECTED')
ORDER BY created_at DESC;

-- Get conflicts (rejected bookings)
SELECT * FROM events_log
WHERE clinic_id = 'clinic-001'
AND event_type = 'BOOKING_REJECTED'
AND details->>'reason' = 'capacity_exceeded';
```

---

## Testing

### Running Tests

```bash
# Install test dependencies
pip install pytest pytest-asyncio

# Run all tests
pytest backend/tests/test_room_manager.py -v

# Run specific test
pytest backend/tests/test_room_manager.py::test_concurrent_bookings_race_condition -v
```

### Test Coverage

The test suite covers:

1. ✅ Basic capacity (N rooms, N appointments)
2. ✅ Capacity exceeded ((N+1) appointments blocked)
3. ✅ Practitioner preferred room assignment
4. ✅ Preferred room fallback when occupied
5. ✅ Overlapping appointments detection
6. ✅ Adjacent appointments (no gap)
7. ✅ Cancellation freeing room
8. ✅ Concurrent bookings (race conditions)
9. ✅ Get available rooms
10. ✅ Check capacity

### Test Database Setup

Set `TEST_DATABASE_URL` environment variable:

```bash
export TEST_DATABASE_URL="postgresql://user:pass@localhost/test_roommanager"
```

---

## Integration with Jane App

### Current Status: Simulated Environment

Since we don't have an active Jane account, the system works with simulated Jane data structures. The integration is designed to work seamlessly when real Jane data is provided.

### Data Mapping

| Jane Field | RoomManager Field |
|------------|-------------------|
| `appointment.id` | `appointments_cache.id` |
| `appointment.start_at` | `appointments_cache.start_at` |
| `appointment.end_at` | `appointments_cache.end_at` |
| `appointment.practitioner.id` | `appointments_cache.practitioner_id` |
| `appointment.status` | `appointments_cache.status` |

### Integration Strategies

#### Strategy 1: Manual Data Sync (CSV/Spreadsheet)

1. Export Jane schedule as CSV
2. Import into RoomManager
3. Process appointments
4. Export "safe schedule" with room assignments

**Pros:**
- Simple, no API required
- Works with any Jane subscription tier

**Cons:**
- Manual process
- Not real-time
- Requires reconciliation

#### Strategy 2: Automated Scraping/Calendar Subscribe

1. Subscribe to Jane calendar feed (iCal)
2. Parse calendar events
3. Trigger RoomManager on updates
4. Reconcile with Jane schedule

**Pros:**
- Automated
- Near real-time

**Cons:**
- Privacy/security concerns
- Fragile (calendar format changes)
- May miss some events

#### Strategy 3: Webhook Integration (If Available)

1. Configure Jane webhooks
2. Receive appointment events
3. Process in RoomManager
4. Update Jane with room assignments

**Pros:**
- Real-time
- Reliable
- Official integration

**Cons:**
- Requires Jane API access
- May not be available

### Recommended Approach

**For Production:**
1. Start with **Strategy 1** (Manual CSV sync) for validation
2. Move to **Strategy 2** (Calendar subscribe) for automation
3. Upgrade to **Strategy 3** (Webhooks) if Jane API becomes available

**For Development/Testing:**
- Use simulated data (as currently implemented)
- Test with realistic Jane-like data structures

---

## Limitations & Assumptions

### Assumptions

1. **Rooms are Interchangeable**: All rooms can be used for any appointment type
   - *Exception*: Practitioner preferences may indicate specialization

2. **1:1 Room:Appointment Ratio**: Each room can hold 1 appointment at a time
   - *Future*: Could support multi-appointment rooms (group therapy)

3. **Appointments Come from Jane**: All appointments originate from Jane App
   - *Reality*: Some appointments may be created directly in Jane (bypassing webhooks)

4. **Time Zones**: All times normalized to UTC
   - *Assumption*: Jane provides UTC times

### Limitations

1. **No Official Jane API**: Integration relies on unofficial methods
   - *Risk*: May miss appointments created directly in Jane
   - *Mitigation*: Polling/reconciliation jobs

2. **Webhook Reliability**: Webhooks may be delayed or missed
   - *Risk*: Appointments may not be processed immediately
   - *Mitigation*: Polling fallback

3. **State Synchronization**: RoomManager state may drift from Jane
   - *Risk*: Room assignments may not reflect in Jane
   - *Mitigation*: Reconciliation jobs, manual sync

4. **Force Assign Override**: Admins can override capacity checks
   - *Risk*: May create double-bookings
   - *Mitigation*: Validation warnings, audit logging

---

## Best Practices

### For Clinic Administrators

1. **Set Practitioner Preferences**: Configure preferred rooms for each practitioner
2. **Monitor Conflicts**: Regularly check `BOOKING_REJECTED` events
3. **Reconcile Daily**: Compare RoomManager assignments with Jane schedule
4. **Review Logs**: Check audit trail for unusual patterns

### For Developers

1. **Always Use RoomManager**: Don't bypass capacity checks
2. **Handle Rejections**: Provide clear error messages to users
3. **Log Everything**: All booking operations should be logged
4. **Test Concurrency**: Use `simulate_concurrent_booking` for testing
5. **Monitor Capacity**: Track capacity metrics over time

### For Integration

1. **Validate Data**: Ensure Jane data is properly formatted
2. **Handle Errors**: Gracefully handle Jane API failures
3. **Reconcile Regularly**: Run daily reconciliation jobs
4. **Monitor Sync**: Track sync status and failures

---

## Troubleshooting

### Common Issues

**Issue: Bookings Rejected Despite Available Rooms**

*Cause*: Capacity check may be too strict, or rooms may be blocked

*Solution*:
1. Check room status: `SELECT * FROM rooms WHERE clinic_id = '...'`
2. Check room blocks: `SELECT * FROM rooms WHERE block_until > NOW()`
3. Verify capacity: Use `check_capacity()` to debug

**Issue: Preferred Room Not Assigned**

*Cause*: Preferred room may be occupied or preference not set

*Solution*:
1. Check preferences: `GET /admin/preferences/practitioner-room?practitioner_id=...`
2. Check room availability: Use `get_available_rooms()`
3. Verify preference priority: Should be `priority = 1`

**Issue: Concurrent Bookings Both Succeed**

*Cause*: Lock may not be working correctly

*Solution*:
1. Check lock implementation: Verify PostgreSQL advisory locks
2. Check lock timeout: May need to increase retry delay
3. Review logs: Check for lock acquisition failures

**Issue: Appointments Missing from RoomManager**

*Cause*: Webhook may have failed or appointment created directly in Jane

*Solution*:
1. Check webhook logs: Review `events_log` for webhook events
2. Run reconciliation: Compare Jane schedule with RoomManager
3. Enable polling: Use polling fallback to catch missed events

---

## Future Enhancements

### Planned Features

1. **Multi-Appointment Rooms**: Support for group therapy rooms (capacity > 1)
2. **Equipment Requirements**: Room assignments based on equipment needs
3. **Accessibility Requirements**: Consider accessibility when assigning rooms
4. **Waitlist Auto-Assignment**: Automatically assign rooms when they free up
5. **Real-Time Capacity Display**: Show available rooms in UI
6. **Advanced Conflict Resolution**: Suggest alternative times when capacity exceeded

### API Improvements

1. **Batch Operations**: Assign multiple appointments at once
2. **Bulk Preference Import**: Import preferences from CSV
3. **Capacity Forecasting**: Predict capacity for future dates
4. **Analytics Endpoints**: Room utilization metrics

---

## Support & Contact

For issues, questions, or contributions:

1. **Documentation**: See this file and `CODE_REVIEW_REPORT.md`
2. **Tests**: Run test suite to verify functionality
3. **Logs**: Check `events_log` table for audit trail
4. **API**: Use `/health` endpoint to verify system status

---

## Changelog

### Version 2.0 (2025-11-30)

- ✅ Added capacity enforcement (pre-booking validation)
- ✅ Implemented practitioner-room preferences
- ✅ Enhanced atomic booking operations
- ✅ Added comprehensive test suite
- ✅ Improved logging and audit trail
- ✅ Added concurrent booking simulation
- ✅ Created API endpoints for preferences

### Version 1.0 (Previous)

- Basic room assignment
- Webhook handling
- Database schema

---

## Appendix: Example Usage

### Complete Booking Flow

```python
from room_manager import RoomManager
from datetime import datetime, timezone

# Initialize manager
manager = RoomManager("clinic-001")

# Create appointment (from Jane webhook)
appointment_data = {
    "id": "apt-123",
    "practitioner_id": "practitioner-456",
    "start_at": "2025-12-01T10:00:00Z",
    "end_at": "2025-12-01T11:00:00Z"
}

# Assign room
result = await manager.assign_room(
    practitioner_id=appointment_data["practitioner_id"],
    appointment_id=appointment_data["id"],
    appointment_start=datetime.fromisoformat(appointment_data["start_at"].replace("Z", "+00:00")),
    appointment_end=datetime.fromisoformat(appointment_data["end_at"].replace("Z", "+00:00")),
    assigned_by="webhook",
    source="jane_webhook"
)

if result["success"]:
    print(f"✅ Assigned {result['room_name']} to appointment")
    if result["preferred_room_used"]:
        print("   Used practitioner's preferred room")
else:
    print(f"❌ Rejected: {result['reason']}")
    print(f"   Capacity: {result['capacity_info']['occupied']}/{result['capacity_info']['total']}")

# Later: Cancel appointment
release_result = await manager.release_room("apt-123", actor="admin")
if release_result["success"]:
    print(f"✅ Released {release_result['room_name']}")
```

