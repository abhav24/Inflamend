import { useCallback, useEffect, useRef, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Clipboard,
  FlatList,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  Text,
  View,
} from 'react-native';
import { format } from 'date-fns';
import { supabase } from '../../lib/supabase';
import { ENV } from '../../lib/env';
import { ChatMessage, ChatRole } from '../../types';
import { useAuthStore } from '../../store/authStore';
import { STARTER_QUESTIONS } from '../../constants';
import { useColors } from '../../constants/colors';
import {
  AppCard,
  AppIcon,
  GlassTextInput,
  PressScale,
} from '../../components/ui/DesignPrimitives';
import { appendDemoRecord, getDemoCollection } from '../../lib/demoData';
import { selectionHaptic, successHaptic } from '../../lib/haptics';

function makeId() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (char) => {
    const random = (Math.random() * 16) | 0;
    return (char === 'x' ? random : (random & 0x3) | 0x8).toString(16);
  });
}

function demoAssistantReply(input: string) {
  if (input.toLowerCase().includes('flare')) {
    return 'A sudden jump in pain, urgency, blood, or fatigue can point to a flare. Log the change, hydrate, and contact your clinician if symptoms are escalating.';
  }
  if (input.toLowerCase().includes('food')) {
    return 'Try logging the meal, timing, and whether it felt like a trigger. Repeated patterns over a week are usually more useful than a single meal.';
  }
  return 'I can help you think through symptoms, food patterns, medications, and what to log next. Ask about anything you are tracking today.';
}

export default function ChatScreen() {
  const C = useColors();
  const { userId } = useAuthStore();
  const flatListRef = useRef<FlatList<ChatMessage>>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [sending, setSending] = useState(false);
  const [initialLoad, setInitialLoad] = useState(true);
  const [initialLoadError, setInitialLoadError] = useState<string | null>(null);

  const fetchMessages = useCallback(async () => {
    if (!userId) {
      setMessages([]);
      setInitialLoad(false);
      return;
    }

    try {
      setInitialLoadError(null);
      if (ENV.DEMO_MODE) {
        const demoMessages = await getDemoCollection('chat_messages');
        setMessages(demoMessages);
      } else {
        const { data, error } = await supabase
          .from('chat_messages')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', { ascending: true });
        if (error) {
          setInitialLoadError('Could not load chat history.');
        } else {
          setMessages(data ?? []);
        }
      }
    } catch {
      setInitialLoadError('Could not load chat history.');
    } finally {
      setInitialLoad(false);
    }
  }, [userId]);

  useEffect(() => {
    fetchMessages();
  }, [fetchMessages]);

  useEffect(() => {
    if (messages.length === 0) return;
    const timer = setTimeout(() => flatListRef.current?.scrollToEnd({ animated: true }), 120);
    return () => clearTimeout(timer);
  }, [messages]);

  const sendMessage = useCallback(async (text: string) => {
    const trimmed = text.trim();
    if (!trimmed || !userId || sending || loading) return;

    setSending(true);
    setInput('');

    const userMessage: ChatMessage = {
      id: makeId(),
      user_id: userId,
      role: 'user' as ChatRole,
      content: trimmed,
      created_at: new Date().toISOString(),
    };

    setMessages((current) => [...current, userMessage]);

    if (ENV.DEMO_MODE) {
      await appendDemoRecord('chat_messages', userMessage);
      const assistantMessage: ChatMessage = {
        id: makeId(),
        user_id: userId,
        role: 'assistant',
        content: demoAssistantReply(trimmed),
        created_at: new Date().toISOString(),
      };
      await appendDemoRecord('chat_messages', assistantMessage);
      setMessages((current) => [...current, assistantMessage]);
      setSending(false);
      return;
    }

    await supabase.from('chat_messages').insert(userMessage);
    setSending(false);
    setLoading(true);

    try {
      const history = [...messages, userMessage]
        .slice(-20)
        .map((message) => ({ role: message.role, content: message.content }));
      const { data, error } = await supabase.functions.invoke('chat', {
        body: { messages: history, userId },
      });
      if (error) throw new Error(error.message);

      const assistantMessage: ChatMessage = {
        id: makeId(),
        user_id: userId,
        role: 'assistant',
        content: data?.content ?? 'Sorry, I could not generate a response.',
        created_at: new Date().toISOString(),
      };
      setMessages((current) => [...current, assistantMessage]);
      await supabase.from('chat_messages').insert(assistantMessage);
    } catch {
      setMessages((current) => [
        ...current,
        {
          id: makeId(),
          user_id: userId,
          role: 'assistant',
          content: 'Something went wrong. Please try again in a moment.',
          created_at: new Date().toISOString(),
        },
      ]);
    } finally {
      setLoading(false);
    }
  }, [loading, messages, sending, userId]);

  const renderMessage = ({ item }: { item: ChatMessage }) => {
    const isUser = item.role === 'user';
    return (
      <View style={{ marginBottom: 12, alignItems: isUser ? 'flex-end' : 'flex-start' }}>
        <PressScale
          onPress={() => undefined}
          haptic={false}
          style={{ width: '100%', alignItems: isUser ? 'flex-end' : 'flex-start' }}
        >
          <View style={{ flexDirection: 'row', alignItems: 'flex-end', maxWidth: '88%' }}>
            {!isUser ? (
              <View style={{ marginRight: 8, marginBottom: 2 }}>
                <AppCard style={{ width: 34, height: 34, alignItems: 'center', justifyContent: 'center' }} intensity={60}>
                  <AppIcon symbol="sparkles" fallback="sparkles" size={16} tintColor={C.primary} />
                </AppCard>
              </View>
            ) : null}
            <PressScale
              onPress={() => undefined}
              haptic={false}
              style={{ flexShrink: 1 }}
            >
              <AppCard
                style={{
                  paddingHorizontal: 14,
                  paddingVertical: 12,
                  backgroundColor: isUser ? `${C.primary}E6` : undefined,
                  borderBottomLeftRadius: isUser ? 18 : 6,
                  borderBottomRightRadius: isUser ? 6 : 18,
                }}
                intensity={isUser ? 66 : 48}
              >
                <Text
                  selectable={false}
                  onLongPress={() => {
                    Clipboard.setString(item.content);
                    successHaptic();
                    Alert.alert('Copied', 'Message copied to clipboard.');
                  }}
                  style={{
                    fontSize: 15,
                    lineHeight: 21,
                    color: isUser ? C.onGradient : C.textPrimary,
                  }}
                >
                  {item.content}
                </Text>
                <Text
                  style={{
                    marginTop: 6,
                    fontSize: 11,
                    color: isUser ? `${C.onGradient}B5` : C.textMuted,
                    textAlign: isUser ? 'right' : 'left',
                  }}
                >
                  {format(new Date(item.created_at), 'h:mm a')}
                </Text>
              </AppCard>
            </PressScale>
          </View>
        </PressScale>
      </View>
    );
  };

  if (initialLoad) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
        <ActivityIndicator size="large" color={C.primary} />
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      style={{ flex: 1 }}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      keyboardVerticalOffset={Platform.OS === 'ios' ? 88 : 0}
    >
      <View style={{ paddingHorizontal: 20, paddingTop: Platform.OS === 'ios' ? 58 : 20, paddingBottom: 18, flexDirection: 'row', alignItems: 'center' }}>
        <AppCard style={{ width: 46, height: 46, alignItems: 'center', justifyContent: 'center', marginRight: 12 }} intensity={70}>
          <AppIcon symbol="sparkles" fallback="sparkles" size={20} tintColor={C.primary} />
        </AppCard>
        <View>
          <Text style={{ fontSize: 28, fontWeight: '800', color: C.textPrimary, letterSpacing: -0.5 }}>
            AI Chat
          </Text>
          <Text style={{ marginTop: 3, fontSize: 14, color: C.textSecondary }}>
            Ask about symptoms, meds, or triggers.
          </Text>
        </View>
      </View>

      {initialLoadError ? (
        <View style={{ marginHorizontal: 20, marginBottom: 12 }}>
          <AppCard style={{ padding: 14 }} intensity={50}>
            <Text style={{ fontSize: 13, fontWeight: '600', color: C.danger }}>{initialLoadError}</Text>
          </AppCard>
        </View>
      ) : null}

      {messages.length === 0 && !loading ? (
        <ScrollView contentContainerStyle={{ paddingHorizontal: 20, paddingBottom: 20 }}>
          <AppCard style={{ padding: 20, alignItems: 'center', marginBottom: 18 }} intensity={54}>
            <AppIcon symbol="message.fill" fallback="chatbubble-ellipses" size={34} tintColor={C.primary} />
            <Text style={{ marginTop: 14, fontSize: 22, fontWeight: '700', color: C.textPrimary, letterSpacing: -0.4 }}>
              Start a conversation
            </Text>
            <Text style={{ marginTop: 6, textAlign: 'center', fontSize: 15, lineHeight: 22, color: C.textSecondary }}>
              Your assistant can help you understand patterns in symptoms, food, and medication logs.
            </Text>
          </AppCard>

          <Text style={{ marginBottom: 10, fontSize: 12, fontWeight: '700', color: C.textMuted, textTransform: 'uppercase', letterSpacing: 0.32 }}>
            Starter Questions
          </Text>
          {STARTER_QUESTIONS.map((question) => (
            <PressScale
              key={question}
              onPress={() => {
                selectionHaptic();
                setInput(question);
              }}
            >
              <AppCard style={{ padding: 16, marginBottom: 10 }} intensity={46}>
                <View style={{ flexDirection: 'row', alignItems: 'center' }}>
                  <View style={{ flex: 1 }}>
                    <Text style={{ fontSize: 15, lineHeight: 20, color: C.textPrimary }}>
                      {question}
                    </Text>
                  </View>
                  <AppIcon symbol="arrow.up.left.and.arrow.down.right" fallback="arrow-forward-outline" size={15} tintColor={C.primary} />
                </View>
              </AppCard>
            </PressScale>
          ))}
        </ScrollView>
      ) : (
        <FlatList
          ref={flatListRef}
          data={messages}
          keyExtractor={(item) => item.id}
          renderItem={renderMessage}
          contentContainerStyle={{ paddingHorizontal: 16, paddingBottom: 18 }}
          showsVerticalScrollIndicator={false}
          onContentSizeChange={() => flatListRef.current?.scrollToEnd({ animated: true })}
          ListFooterComponent={
            loading ? (
              <View style={{ marginTop: 12, alignItems: 'flex-start' }}>
                <AppCard style={{ paddingHorizontal: 16, paddingVertical: 14 }} intensity={48}>
                  <ActivityIndicator size="small" color={C.textSecondary} />
                </AppCard>
              </View>
            ) : null
          }
        />
      )}

      <View style={{ paddingHorizontal: 16, paddingVertical: 12, gap: 10 }}>
        <GlassTextInput
          value={input}
          onChangeText={setInput}
          placeholder="Ask me anything…"
          multiline
          submitBehavior="submit"
          onSubmitEditing={() => sendMessage(input)}
          inputStyle={{ minHeight: 56, maxHeight: 120, textAlignVertical: 'top' }}
        />
        <PressScale
          disabled={!input.trim() || sending || loading}
          onPress={() => sendMessage(input)}
        >
          <AppCard style={{ alignItems: 'center', justifyContent: 'center', minHeight: 52, backgroundColor: !input.trim() || sending || loading ? undefined : `${C.primary}E6` }} intensity={60}>
            {sending ? (
              <ActivityIndicator size="small" color={C.onGradient} />
            ) : (
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                <AppIcon symbol="arrow.up.circle.fill" fallback="arrow-up" size={18} tintColor={!input.trim() || sending || loading ? C.textMuted : C.onGradient} />
                <Text style={{ fontSize: 16, fontWeight: '700', color: !input.trim() || sending || loading ? C.textMuted : C.onGradient }}>
                  Send
                </Text>
              </View>
            )}
          </AppCard>
        </PressScale>
      </View>
    </KeyboardAvoidingView>
  );
}
