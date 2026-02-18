# Bug Report Template

Use this template to report bugs found in the Modaics iOS app.

---

## Bug Report

### Summary
<!-- Brief one-line description of the issue -->

### Steps to Reproduce
1. 
2. 
3. 

### Expected Behavior
<!-- What should happen -->

### Actual Behavior
<!-- What actually happens -->

### Screenshots / Videos
<!-- Attach any visual evidence -->

### Environment
| Item | Details |
|------|---------|
| Device | <!-- e.g., iPhone 15 Pro --> |
| iOS Version | <!-- e.g., 17.4 --> |
| App Version | <!-- e.g., 1.2.0 (45) --> |
| Build | <!-- Debug/Release/TestFlight --> |

### Severity
- [ ] Critical - App crashes or data loss
- [ ] High - Major feature broken
- [ ] Medium - Feature works with workarounds
- [ ] Low - Minor UI/UX issue

### Area
- [ ] Authentication
- [ ] Payments
- [ ] Visual Search
- [ ] Item Listing
- [ ] Sketchbook
- [ ] Profile/Settings
- [ ] UI/Design
- [ ] Performance
- [ ] Other: _______

### Logs / Error Messages
```
<!-- Paste any relevant console logs or error messages -->
```

### Additional Context
<!-- Any other information that might help -->

---

## Checklist for Reporter
- [ ] I can consistently reproduce this bug
- [ ] I have tested on the latest build
- [ ] I have searched existing issues to avoid duplicates
- [ ] I have included all relevant information

## Checklist for Developer
- [ ] Bug reproduced in development environment
- [ ] Root cause identified
- [ ] Fix implemented
- [ ] Unit tests added/updated
- [ ] Fix tested on device
- [ ] Code reviewed
- [ ] Merged to main branch

---

## Example Bug Report

**Summary:** App crashes when tapping "Pay with Apple Pay" button

**Steps to Reproduce:**
1. Add item to cart
2. Go to checkout
3. Tap "Pay with Apple Pay"

**Expected:** Apple Pay sheet should appear

**Actual:** App crashes immediately

**Environment:** iPhone 14 Pro, iOS 17.2, v1.1.0

**Severity:** Critical

**Area:** Payments

**Logs:**
```
Terminating app due to uncaught exception 'NSInvalidArgumentException',
reason: '-[ModaicsAppTemp.PaymentService processApplePay:]: unrecognized selector sent to instance'
```
