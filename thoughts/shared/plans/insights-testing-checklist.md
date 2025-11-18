# Insights Feature Testing Checklist

## Cloud Function Testing
- [ ] Deploy generateInsight function successfully
- [ ] Create test journal message with AI response
- [ ] Verify insight document created in Firestore
- [ ] Check insight fields are populated correctly
- [ ] Test update logic (add message within 24 hours)
- [ ] Verify global insight aggregation
- [ ] Check Cloud Function logs for errors

## Repository Testing
- [ ] Sync insights from Firestore to local Isar
- [ ] Watch global insights stream (test real-time updates)
- [ ] Watch thread insights stream
- [ ] Test offline mode (disconnect network, verify cached data)
- [ ] Test online mode (reconnect, verify sync)
- [ ] Verify bidirectional sync updates local DB

## UI Testing
- [ ] Mock data displays correctly in charts
- [ ] Bar chart shows mood trends
- [ ] Bar colors match emotions
- [ ] Pie chart percentages add up to 100%
- [ ] Empty state displays when no insights
- [ ] Charts update when new insight arrives
- [ ] Scrolling works on small screens
- [ ] Dark mode compatibility
- [ ] Legend displays all emotions

## Performance Testing
- [ ] Charts render in < 500ms with 20 insights
- [ ] No frame drops during chart animations
- [ ] Memory usage stable during scrolling
- [ ] Cloud Function completes in < 5 seconds

## Edge Cases
- [ ] Single insight displays correctly
- [ ] Very high mood score (0.95+) renders properly
- [ ] Very low mood score (0.1-) renders properly
- [ ] Long keyword lists don't overflow
- [ ] Long summaries wrap correctly
- [ ] Multiple threads with same timestamp

## Firestore Security
- [ ] Users can only read their own insights
- [ ] Users cannot read other users' insights
- [ ] Insight creation is allowed for authenticated users
- [ ] Insight updates are allowed only for owners
- [ ] Insight deletion is disabled (soft delete only)

## Firestore Indexes
- [ ] All necessary indexes are deployed
- [ ] Queries for global insights work without errors
- [ ] Queries for thread insights work without errors
- [ ] Complex queries (userId + threadId + periodEndMillis) work

## Integration Testing
- [ ] End-to-end flow: Journal message → AI response → Insight generated → UI updates
- [ ] Multiple threads generate separate thread insights
- [ ] Thread insights aggregate into global insight
- [ ] Offline-first sync works correctly
- [ ] App handles no insights state gracefully












