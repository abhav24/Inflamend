import { useEffect, useRef, useState, useCallback } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  FlatList,
  KeyboardAvoidingView,
  Platform,
  StyleSheet,
  ActivityIndicator,
} from 'react-native';
import { supabase } from '../../lib/supabase';
import { useAuthStore } from '../../store/authStore';
import { ChatMessage, ChatRole } from '../../types';
import { Colors } from '../../constants/colors';
import { STARTER_QUESTIONS } from '../../constants';
import { format } from 'date-fns';

function makeId() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    return (c === 'x' ? r : (r & 0x3) | 0x8).toString(16);
  });
}

export default function ChatScreen() {
  const { userId } = useAuthStore();
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [sending, setSending] = useState(false);
  const [initialLoad, setInitialLoad] = useState(true);
  const flatListRef = useRef<FlatList<ChatMessage>>(null);

  const fetchMessages = useCallback(async () => {
    if (!userId) return;
    const { data, error } = await supabase
      .from('chat_messages')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: true });
    if (error) {
      console.error('fetchMessages', error);
      return;
    }
    setMessages(data ?? []);
    setInitialLoad(false);
  }, [userId]);

  useEffect(() => {
    fetchMessages();
  }, []);

  useEffect(() => {
    if (messages.length > 0) {
      setTimeout(() => {
        flatListRef.current?.scrollToEnd({ animated: true });
      }, 100);
    }
  }, [messages]);

  const sendMessage = useCallback(async (text: string) => {
    const trimmed = text.trim();
    if (!trimmed || !userId || sending || loading) return;

    setSending(true);
    setInput('');

    const userMsg: ChatMessage = {
      id: makeId(),
      user_id: userId,
      role: 'user' as ChatRole,
      content: trimmed,
      created_at: new Date().toISOString(),
    };

    setMessages((prev) => [...prev, userMsg]);

    // Save user message to supabase
    await supabase.from('chat_messages').insert({
      id: userMsg.id,
      user_id: userId,
      role: userMsg.role,
      content: userMsg.content,
      created_at: userMsg.created_at,
    });

    setSending(false);
    setLoading(true);

    try {
      // Build the last 20 messages including the one just sent
      const allMessages = [...messages, userMsg];
      const last20 = allMessages.slice(-20).map((m) => ({
        role: m.role,
        content: m.content,
      }));

      const { data: fnData, error: fnError } = await supabase.functions.invoke('chat', {
        body: { messages: last20, userId },
      });

      if (fnError) {
        throw new Error(fnError.message);
      }

      const responseText: string = fnData?.content ?? 'Sorry, I could not generate a response.';

      const assistantMsg: ChatMessage = {
        id: makeId(),
        user_id: userId,
        role: 'assistant' as ChatRole,
        content: responseText,
        created_at: new Date().toISOString(),
      };

      setMessages((prev) => [...prev, assistantMsg]);

      await supabase.from('chat_messages').insert({
        id: assistantMsg.id,
        user_id: userId,
        role: assistantMsg.role,
        content: assistantMsg.content,
        created_at: assistantMsg.created_at,
      });
    } catch (err: any) {
      console.error('chat error', err);
      const errMsg: ChatMessage = {
        id: makeId(),
        user_id: userId,
        role: 'assistant' as ChatRole,
        content: 'Sorry, something went wrong. Please try again in a moment.',
        created_at: new Date().toISOString(),
      };
      setMessages((prev) => [...prev, errMsg]);
    } finally {
      setLoading(false);
    }
  }, [userId, messages, sending, loading]);

  const handleSend = () => sendMessage(input);
  const handleStarterQuestion = (question: string) => sendMessage(question);

  const renderMessage = ({ item }: { item: ChatMessage }) => {
    const isUser = item.role === 'user';
    return (
      <View style={[styles.bubbleWrapper, isUser ? styles.bubbleWrapperUser : styles.bubbleWrapperAssistant]}>
        {!isUser && (
          <View style={styles.avatarCircle}>
            <Text style={styles.avatarText}>AI</Text>
          </View>
        )}
        <View style={[styles.bubble, isUser ? styles.bubbleUser : styles.bubbleAssistant]}>
          <Text style={[styles.bubbleText, isUser ? styles.bubbleTextUser : styles.bubbleTextAssistant]}>
            {item.content}
          </Text>
          <Text style={[styles.bubbleTime, isUser ? styles.bubbleTimeUser : styles.bubbleTimeAssistant]}>
            {format(new Date(item.created_at), 'h:mm a')}
          </Text>
        </View>
      </View>
    );
  };

  const renderTypingIndicator = () => {
    if (!loading) return null;
    return (
      <View style={[styles.bubbleWrapper, styles.bubbleWrapperAssistant]}>
        <View style={styles.avatarCircle}>
          <Text style={styles.avatarText}>AI</Text>
        </View>
        <View style={[styles.bubble, styles.bubbleAssistant, styles.typingBubble]}>
          <Text style={styles.typingText}>...</Text>
        </View>
      </View>
    );
  };

  if (initialLoad) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color={Colors.primary} />
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      keyboardVerticalOffset={Platform.OS === 'ios' ? 88 : 0}
    >
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>AI Health Assistant</Text>
        <Text style={styles.headerSubtitle}>Your AI health companion</Text>
      </View>

      {/* Messages / Starter Questions */}
      {messages.length === 0 && !loading ? (
        <View style={styles.starterContainer}>
          <Text style={styles.starterIntro}>
            Hi! I'm your IBD support assistant. How can I help you today?
          </Text>
          <Text style={styles.starterHint}>Here are some things you can ask me:</Text>
          {STARTER_QUESTIONS.map((question) => (
            <TouchableOpacity
              key={question}
              style={styles.starterButton}
              onPress={() => handleStarterQuestion(question)}
              activeOpacity={0.7}
            >
              <Text style={styles.starterButtonText}>{question}</Text>
            </TouchableOpacity>
          ))}
        </View>
      ) : (
        <FlatList
          ref={flatListRef}
          data={messages}
          keyExtractor={(item) => item.id}
          renderItem={renderMessage}
          contentContainerStyle={styles.messageList}
          ListFooterComponent={renderTypingIndicator}
          onContentSizeChange={() => flatListRef.current?.scrollToEnd({ animated: true })}
          showsVerticalScrollIndicator={false}
        />
      )}

      {/* Input Row */}
      <View style={styles.inputRow}>
        <TextInput
          style={styles.textInput}
          value={input}
          onChangeText={setInput}
          placeholder="Ask me anything about IBD..."
          placeholderTextColor={Colors.placeholder}
          multiline
          maxLength={1000}
          returnKeyType="default"
        />
        <TouchableOpacity
          style={[styles.sendButton, (!input.trim() || sending || loading) && styles.sendButtonDisabled]}
          onPress={handleSend}
          disabled={!input.trim() || sending || loading}
          activeOpacity={0.8}
        >
          {sending ? (
            <ActivityIndicator size="small" color={Colors.white} />
          ) : (
            <Text style={styles.sendButtonText}>Send</Text>
          )}
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: Colors.background,
  },
  header: {
    backgroundColor: Colors.white,
    paddingTop: 56,
    paddingBottom: 14,
    paddingHorizontal: 20,
    borderBottomWidth: 1,
    borderBottomColor: Colors.border,
    shadowColor: '#000',
    shadowOpacity: 0.04,
    shadowRadius: 4,
    elevation: 2,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  headerSubtitle: {
    fontSize: 12,
    color: Colors.textSecondary,
    marginTop: 2,
  },
  starterContainer: {
    flex: 1,
    paddingHorizontal: 20,
    paddingTop: 24,
  },
  starterIntro: {
    fontSize: 16,
    color: Colors.textPrimary,
    marginBottom: 16,
    fontWeight: '500',
    lineHeight: 22,
  },
  starterHint: {
    fontSize: 13,
    color: Colors.textSecondary,
    marginBottom: 12,
  },
  starterButton: {
    backgroundColor: Colors.white,
    borderRadius: 12,
    padding: 14,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  starterButtonText: {
    fontSize: 14,
    color: Colors.primary,
    fontWeight: '500',
  },
  messageList: {
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  bubbleWrapper: {
    flexDirection: 'row',
    marginBottom: 12,
    alignItems: 'flex-end',
  },
  bubbleWrapperUser: {
    justifyContent: 'flex-end',
  },
  bubbleWrapperAssistant: {
    justifyContent: 'flex-start',
  },
  avatarCircle: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: Colors.primaryLight,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 8,
    flexShrink: 0,
  },
  avatarText: {
    fontSize: 10,
    fontWeight: '700',
    color: Colors.primary,
  },
  bubble: {
    maxWidth: '75%',
    borderRadius: 16,
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  bubbleUser: {
    backgroundColor: Colors.primary,
    borderBottomRightRadius: 4,
  },
  bubbleAssistant: {
    backgroundColor: Colors.white,
    borderBottomLeftRadius: 4,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  bubbleText: {
    fontSize: 15,
    lineHeight: 21,
  },
  bubbleTextUser: {
    color: Colors.white,
  },
  bubbleTextAssistant: {
    color: Colors.textPrimary,
  },
  bubbleTime: {
    fontSize: 11,
    marginTop: 4,
  },
  bubbleTimeUser: {
    color: 'rgba(255,255,255,0.7)',
    textAlign: 'right',
  },
  bubbleTimeAssistant: {
    color: Colors.textMuted,
  },
  typingBubble: {
    paddingVertical: 14,
    paddingHorizontal: 18,
  },
  typingText: {
    fontSize: 20,
    color: Colors.textSecondary,
    letterSpacing: 4,
  },
  inputRow: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: Colors.white,
    borderTopWidth: 1,
    borderTopColor: Colors.border,
    gap: 10,
  },
  textInput: {
    flex: 1,
    backgroundColor: Colors.background,
    borderRadius: 22,
    paddingHorizontal: 16,
    paddingVertical: Platform.OS === 'ios' ? 10 : 8,
    fontSize: 15,
    color: Colors.textPrimary,
    borderWidth: 1,
    borderColor: Colors.border,
    maxHeight: 120,
  },
  sendButton: {
    backgroundColor: Colors.primary,
    borderRadius: 22,
    paddingHorizontal: 18,
    paddingVertical: 10,
    justifyContent: 'center',
    alignItems: 'center',
    minWidth: 64,
    height: 42,
  },
  sendButtonDisabled: {
    backgroundColor: Colors.border,
  },
  sendButtonText: {
    color: Colors.white,
    fontWeight: '700',
    fontSize: 14,
  },
});
