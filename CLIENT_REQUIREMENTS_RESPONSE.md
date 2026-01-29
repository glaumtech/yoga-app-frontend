# Client Requirements - Response & Implementation Plan

## Requirements Received

1. **Separate Radio Buttons for All Standards**: Need individual radio buttons for each standard (instead of grouped standards like "II, III") to get accurate reports.

2. **School Name Dropdown**: Replace text input with a dropdown populated with school names.

3. **Multiple Jury Evaluation**: Ensure 3-5 juries can evaluate the same participant simultaneously (concurrent scoring support).

4. **Jury Multi-Participant Assignment**: One jury should be able to judge 2-3 participants at the same time based on event strength.

---

## Response Message

**Option 1 (Professional & Detailed):**
```
Thank you for the requirements. We acknowledge and will implement the following:

✅ Separate radio buttons for each standard (II, III, IV, V, VI, VII, VIII, IX, X, XI, XII, UG, PG) for accurate reporting
✅ School name dropdown (replacing text input) - will need school master list from backend
✅ Concurrent scoring support for 3-5 juries evaluating the same participant simultaneously
✅ Multi-participant assignment allowing one jury to judge 2-3 participants concurrently

These changes will improve data accuracy, user experience, and system scalability. Implementation timeline will be shared shortly.
```

**Option 2 (Concise):**
```
Noted. We'll implement: (1) Individual standard radio buttons for accurate reports, (2) School name dropdown, (3) Concurrent scoring for 3-5 juries per participant, (4) Multi-participant assignment (2-3 participants per jury). Timeline to follow.
```

**Option 3 (Technical):**
```
Requirements acknowledged:
- Registration: Individual standard radio buttons (II-XII, UG, PG) + School dropdown
- Scoring: Concurrent access for 3-5 juries per participant + Multi-participant assignment (2-3 per jury)
- Backend: Ensure API supports concurrent writes and school master data endpoint

Will proceed with implementation after confirming school master list availability.
```

---

## Implementation Checklist

### 1. Registration Form Updates
- [ ] Replace grouped standards with individual radio buttons (II, III, IV, V, VI, VII, VIII, IX, X, XI, XII, UG, PG)
- [ ] Update `AppConstants.standards` to individual values
- [ ] Replace school name TextField with DropdownButton
- [ ] Add API endpoint to fetch school master list
- [ ] Update `ParticipantModel` if needed for standard field
- [ ] Update validation logic

### 2. School Dropdown Implementation
- [ ] Create school master list API endpoint (or use existing)
- [ ] Add school dropdown in registration form
- [ ] Handle school search/filter if list is large
- [ ] Update participant creation/update logic

### 3. Concurrent Scoring Support
- [ ] Verify backend API supports concurrent score submissions
- [ ] Ensure database handles simultaneous writes (3-5 juries)
- [ ] Add optimistic locking or conflict resolution if needed
- [ ] Test concurrent scoring scenarios

### 4. Multi-Participant Assignment
- [ ] Update assignment logic to allow 2-3 participants per jury
- [ ] Modify judge scoring screen to show multiple participants
- [ ] Add participant switching/navigation for judges
- [ ] Update assignment validation rules

---

## Technical Considerations

### Backend Requirements
1. **School Master API**: Need endpoint to fetch school list (e.g., `/schools/list`)
2. **Concurrent Scoring**: Database should handle simultaneous score entries without conflicts
3. **Assignment Limits**: Backend should validate and enforce 2-3 participants per jury limit

### Frontend Changes
1. **Standards**: Update from grouped to individual values
2. **School Dropdown**: Replace TextField with DropdownButtonFormField
3. **Scoring UI**: Ensure multiple juries can access same participant simultaneously
4. **Judge Dashboard**: Show multiple assigned participants with quick navigation

---

## Questions for Client

1. **School Master List**: Do you have a master list of schools, or should we create a school management feature?
2. **Standard Values**: Confirm exact standard values needed (II, III, IV, V, VI, VII, VIII, IX, X, XI, XII, UG, PG)?
3. **Concurrent Access**: Should we show real-time updates when other juries are scoring the same participant?
4. **Assignment Rules**: Any specific rules for assigning 2-3 participants to a jury (e.g., same category, different categories)?

---

## Estimated Timeline

- **Registration Updates**: 2-3 days
- **School Dropdown**: 1-2 days (depends on API availability)
- **Concurrent Scoring**: 2-3 days (testing required)
- **Multi-Participant Assignment**: 2-3 days
- **Total**: ~7-11 days (depending on backend API availability)

---

## Notes

- Current system supports 5 juries (`juryCount = 5`) which meets the 3-5 requirement
- Need to verify backend can handle concurrent writes for same participant
- School dropdown may require search/filter functionality if list is extensive
- Multi-participant assignment needs UI/UX consideration for judge workflow


