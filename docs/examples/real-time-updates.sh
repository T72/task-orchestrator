#!/bin/bash
# Real-Time Coordination Example
# Shows progress tracking and instant unblocking

echo "=== Real-Time Progress Tracking ==="
echo "See how teams stay synchronized without meetings"
echo

# Create a feature that requires careful coordination
FEATURE=$(./tm add "Critical Security Fix" -p critical | grep -o '[a-f0-9]\{8\}')
REVIEW=$(./tm add "Security Review" --depends-on $FEATURE | grep -o '[a-f0-9]\{8\}')
DEPLOY=$(./tm add "Emergency Deploy" --depends-on $REVIEW | grep -o '[a-f0-9]\{8\}')

echo "=== Initial Status ==="
./tm list

echo
echo "=== Developer Updates Progress in Real-Time ==="
./tm update $FEATURE --status in_progress
./tm progress $FEATURE "10% - Identified vulnerability in auth module"
sleep 1
./tm progress $FEATURE "40% - Developed fix, writing tests"
sleep 1
./tm progress $FEATURE "70% - Tests passing, code review requested"
sleep 1
./tm progress $FEATURE "100% - Fix complete and verified"
./tm complete $FEATURE

echo
echo "=== Security Review Automatically Unblocked! ==="
./tm list
echo "Notice: Security Review is now 'pending' instead of 'blocked'"

echo
echo "=== Security Team Takes Over ==="
./tm update $REVIEW --status in_progress
./tm share $REVIEW "CONFIRMED: Fix addresses CVE-2024-12345"
./tm complete $REVIEW

echo
echo "=== Deploy Automatically Unblocked! ==="
./tm list

echo
echo "=== Deploy Team Can Start Immediately ==="
./tm update $DEPLOY --status in_progress
./tm progress $DEPLOY "Deploying to staging..."
./tm progress $DEPLOY "Staging tests passed"
./tm progress $DEPLOY "Rolling out to production..."
./tm complete $DEPLOY

echo
echo "=== Mission Complete! ==="
./tm list

echo
echo "💡 What Just Happened:"
echo "   • No manual coordination needed"
echo "   • Each team started instantly when unblocked"
echo "   • Full progress visibility throughout"
echo "   • Context preserved at each handoff"
echo "   • Critical fix deployed in record time!"