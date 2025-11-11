/**
 * Script to generate test journal data for development/testing
 *
 * Usage:
 * 1. Set your user ID below
 * 2. Run: npx ts-node scripts/generate-test-data.ts
 */

import * as admin from 'firebase-admin';
import * as serviceAccount from '../service-account-key.json';

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount as admin.ServiceAccount),
});

const db = admin.firestore();

// CONFIGURATION
const USER_ID = 'YOUR_USER_ID_HERE'; // Replace with your actual user ID
const DAYS_TO_GENERATE = 15;
const THREADS_PER_DAY = 2; // Average threads per day
const MESSAGES_PER_THREAD = 3; // Average messages per thread

// Emotion distribution for variety
enum EmotionType {
  JOY = 0,
  CALM = 1,
  NEUTRAL = 2,
  SADNESS = 3,
  STRESS = 4,
  ANGER = 5,
  FEAR = 6,
  EXCITEMENT = 7,
}

// Sample conversation templates by mood
const conversationTemplates = {
  [EmotionType.JOY]: [
    { user: "I had such an amazing day today!", ai: "That's wonderful to hear! What made your day so special?" },
    { user: "I finally achieved my goal!", ai: "Congratulations! That's a significant accomplishment. How does it feel?" },
    { user: "Everything went perfectly today", ai: "It's great when things align well. What were the highlights?" },
  ],
  [EmotionType.CALM]: [
    { user: "Just enjoying a peaceful morning", ai: "Peaceful moments are precious. What are you doing to relax?" },
    { user: "Feeling centered and balanced", ai: "That's a wonderful state to be in. What helps you maintain this balance?" },
    { user: "Taking things slow today", ai: "Sometimes slowing down is exactly what we need. How are you spending your time?" },
  ],
  [EmotionType.SADNESS]: [
    { user: "Feeling a bit down today", ai: "I'm sorry you're feeling this way. Would you like to talk about what's troubling you?" },
    { user: "Things didn't go as I hoped", ai: "Disappointments can be difficult. What happened?" },
    { user: "Missing someone today", ai: "Missing someone shows how much they mean to you. Tell me about them." },
  ],
  [EmotionType.STRESS]: [
    { user: "So much to do, so little time", ai: "Feeling overwhelmed is tough. What's on your plate right now?" },
    { user: "Work is really getting to me", ai: "Work stress can be challenging. What specific aspects are bothering you?" },
    { user: "Can't seem to catch a break", ai: "It sounds like you're under a lot of pressure. What would help you feel more balanced?" },
  ],
  [EmotionType.EXCITEMENT]: [
    { user: "I can't wait for tomorrow!", ai: "Your excitement is contagious! What's happening tomorrow?" },
    { user: "Something amazing is about to happen", ai: "How exciting! Tell me more about what you're anticipating." },
    { user: "I'm so energized right now!", ai: "That energy is wonderful! What's fueling this excitement?" },
  ],
  [EmotionType.NEUTRAL]: [
    { user: "Just another regular day", ai: "Sometimes routine can be comforting. How's your day going?" },
    { user: "Nothing special happening", ai: "Even ordinary days have their moments. What have you been up to?" },
    { user: "Going through the motions", ai: "How are you feeling about your daily routine?" },
  ],
};

function getRandomEmotion(): EmotionType {
  // Weighted distribution for more realistic variety
  const weights = {
    [EmotionType.JOY]: 20,
    [EmotionType.CALM]: 25,
    [EmotionType.NEUTRAL]: 15,
    [EmotionType.SADNESS]: 15,
    [EmotionType.STRESS]: 15,
    [EmotionType.ANGER]: 3,
    [EmotionType.FEAR]: 2,
    [EmotionType.EXCITEMENT]: 5,
  };

  const total = Object.values(weights).reduce((sum, w) => sum + w, 0);
  let random = Math.random() * total;

  for (const [emotion, weight] of Object.entries(weights)) {
    random -= weight;
    if (random <= 0) {
      return parseInt(emotion) as EmotionType;
    }
  }

  return EmotionType.NEUTRAL;
}

function getRandomTemplate(emotion: EmotionType) {
  const templates = conversationTemplates[emotion] || conversationTemplates[EmotionType.NEUTRAL];
  return templates[Math.floor(Math.random() * templates.length)];
}

function generateThreadTitle(emotion: EmotionType, date: Date): string {
  const titles = {
    [EmotionType.JOY]: ['Amazing Day', 'Great News', 'Wonderful Moment', 'Happy Times'],
    [EmotionType.CALM]: ['Peaceful Thoughts', 'Quiet Reflection', 'Mindful Moment', 'Serene Day'],
    [EmotionType.SADNESS]: ['Tough Day', 'Feeling Low', 'Difficult Moments', 'Heavy Heart'],
    [EmotionType.STRESS]: ['Busy Day', 'Overwhelming Tasks', 'Under Pressure', 'Hectic Schedule'],
    [EmotionType.EXCITEMENT]: ['Exciting News', 'Big Plans', 'Can\'t Wait', 'Something Special'],
    [EmotionType.NEUTRAL]: ['Daily Journal', 'Regular Day', 'Check In', 'Today\'s Thoughts'],
  };

  const emotionTitles = titles[emotion] || titles[EmotionType.NEUTRAL];
  const title = emotionTitles[Math.floor(Math.random() * emotionTitles.length)];
  const dateStr = date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });

  return `${title} - ${dateStr}`;
}

async function generateTestData() {
  console.log(`🚀 Generating test data for user: ${USER_ID}`);
  console.log(`📅 Creating ${DAYS_TO_GENERATE} days of journal entries\n`);

  const now = Date.now();
  let totalThreads = 0;
  let totalMessages = 0;

  for (let day = DAYS_TO_GENERATE - 1; day >= 0; day--) {
    const daysAgo = day;
    const dayTimestamp = now - (daysAgo * 24 * 60 * 60 * 1000);
    const dayDate = new Date(dayTimestamp);

    console.log(`📝 Day ${DAYS_TO_GENERATE - day}/${DAYS_TO_GENERATE}: ${dayDate.toLocaleDateString()}`);

    // Random number of threads for this day (1-3)
    const threadsToday = Math.floor(Math.random() * 2) + THREADS_PER_DAY - 1;

    for (let t = 0; t < threadsToday; t++) {
      const emotion = getRandomEmotion();
      const threadTimestamp = dayTimestamp + (t * 3600000); // Spread throughout the day
      const threadId = `thread_${USER_ID}_${day}_${t}`;

      // Create thread
      const threadTitle = generateThreadTitle(emotion, dayDate);
      console.log(`  📋 Creating thread: "${threadTitle}" (${EmotionType[emotion]})`);

      await db.collection('journalThreads').doc(threadId).set({
        id: threadId,
        userId: USER_ID,
        title: threadTitle,
        createdAtMillis: threadTimestamp,
        lastMessageAtMillis: threadTimestamp,
        updatedAtMillis: threadTimestamp,
        messageCount: 0,
        isDeleted: false,
      });

      totalThreads++;

      // Create messages for this thread
      const messagesToday = Math.floor(Math.random() * 2) + MESSAGES_PER_THREAD - 1;
      let messageCount = 0;

      for (let m = 0; m < messagesToday; m++) {
        const template = getRandomTemplate(emotion);
        const messageTimestamp = threadTimestamp + (m * 600000); // 10 minutes apart

        // User message
        const userMessageId = `msg_${threadId}_${m}_user`;
        await db.collection('journalMessages').doc(userMessageId).set({
          id: userMessageId,
          threadId: threadId,
          userId: USER_ID,
          role: 0, // USER
          type: 0, // TEXT
          content: template.user,
          createdAtMillis: messageTimestamp,
          updatedAtMillis: messageTimestamp,
          isDeleted: false,
          status: 5, // REMOTE_CREATED
        });

        messageCount++;
        totalMessages++;

        // AI response
        const aiMessageId = `msg_${threadId}_${m}_ai`;
        await db.collection('journalMessages').doc(aiMessageId).set({
          id: aiMessageId,
          threadId: threadId,
          userId: USER_ID,
          role: 1, // AI
          type: 0, // TEXT
          content: template.ai,
          createdAtMillis: messageTimestamp + 5000,
          updatedAtMillis: messageTimestamp + 5000,
          isDeleted: false,
          status: 5, // REMOTE_CREATED
        });

        messageCount++;
        totalMessages++;
      }

      // Update thread with final message count
      await db.collection('journalThreads').doc(threadId).update({
        messageCount: messageCount,
        lastMessageAtMillis: threadTimestamp + ((messagesToday - 1) * 600000) + 5000,
      });

      console.log(`    ✅ Added ${messageCount} messages`);
    }

    console.log('');
  }

  console.log('✨ Test data generation complete!');
  console.log(`📊 Summary:`);
  console.log(`   - Threads created: ${totalThreads}`);
  console.log(`   - Messages created: ${totalMessages}`);
  console.log(`\n💡 Next steps:`);
  console.log(`   1. Open the app and log in as user: ${USER_ID}`);
  console.log(`   2. Go to the Journal tab to see your threads`);
  console.log(`   3. Go to the Insights tab to see mood analysis`);
  console.log(`   4. Wait a few minutes for insights to generate automatically`);
  console.log(`   5. Or manually trigger: firebase functions:shell`);
  console.log(`      Then run: generateInsight({data: {threadId: "thread_...", userId: "${USER_ID}", role: 1}})`);
}

// Run the script
generateTestData()
  .then(() => {
    console.log('\n✅ Done!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Error:', error);
    process.exit(1);
  });
