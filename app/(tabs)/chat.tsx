import { useEffect, useRef, useState, useCallback } from 'react';
import {
  View, Text, TextInput, TouchableOpacity, FlatList,
  KeyboardAvoidingView, Platform, ActivityIndicator,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { supabase } from '../../lib/supabase';
import { useAuthStore } from '../../store/authStore';
import { ChatMessage, ChatRole } from '../../types';
import { useColors } from '../../constants/colors';
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
  const C = useColors();
  const [messages, setMessages]         = useState<ChatMessage[]>([]);
  const [input, setInput]               = useState('');
  const [loading, setLoading]           = useState(false);
  const [sending, setSending]           = useState(false);
  const [initialLoad, setInitialLoad]   = useState(true);
  const [initialLoadError, setInitialLoadError] = useState<string | null>(null);
  const flatListRef = useRef<FlatList<ChatMessage>>(null);

  const fetchMessages = useCallback(async () => {
    if (!userId) { setInitialLoad(false); return; }
    try {
      setInitialLoadError(null);
      const { data, error } = await supabase
        .from('chat_messages').select('*').eq('user_id', userId)
        .order('created_at', { ascending: true });
      if (error) { setInitialLoadError('Could not load chat history.'); return; }
      setMessages(data ?? []);
    } catch {
      setInitialLoadError('Could not load chat history.');
    } finally {
      setInitialLoad(false);
    }
  }, [userId]);

  useEffect(() => { fetchMessages(); }, [fetchMessages]);

  useEffect(() => {
    if (messages.length > 0) {
      setTimeout(() => flatListRef.current?.scrollToEnd({ animated: true }), 100);
    }
  }, [messages]);

  const sendMessage = useCallback(async (text: string) => {
    const trimmed = text.trim();
    if (!trimmed || !userId || sending || loading) return;

    setSending(true); setInput('');
    const userMsg: ChatMessage = {
      id: makeId(), user_id: userId, role: 'user' as ChatRole,
      content: trimmed, created_at: new Date().toISOString(),
    };
    setMessages((prev) => [...prev, userMsg]);
    await supabase.from('chat_messages').insert({ ...userMsg });
    setSending(false); setLoading(true);

    try {
      const last20 = [...messages, userMsg].slice(-20).map((m) => ({ role: m.role, content: m.content }));
      const { data: fnData, error: fnError } = await supabase.functions.invoke('chat', {
        body: { messages: last20, userId },
      });
      if (fnError) throw new Error(fnError.message);
      const assistantMsg: ChatMessage = {
        id: makeId(), user_id: userId, role: 'assistant' as ChatRole,
        content: fnData?.content ?? 'Sorry, I could not generate a response.',
        created_at: new Date().toISOString(),
      };
      setMessages((prev) => [...prev, assistantMsg]);
      await supabase.from('chat_messages').insert({ ...assistantMsg });
    } catch {
      setMessages((prev) => [...prev, {
        id: makeId(), user_id: userId!, role: 'assistant' as ChatRole,
        content: 'Something went wrong. Please try again in a moment.',
        created_at: new Date().toISOString(),
      }]);
    } finally {
      setLoading(false);
    }
  }, [userId, messages, sending, loading]);

  const renderMessage = ({ item }: { item: ChatMessage }) => {
    const isUser = item.role === 'user';
    return (
      <View style={{
        flexDirection: 'row', marginBottom: 12, alignItems: 'flex-end',
        justifyContent: isUser ? 'flex-end' : 'flex-start',
      }}>
        {!isUser && (
          <View style={{
            width: 32, height: 32, borderRadius: 10,
            backgroundColor: C.primary + '18',
            alignItems: 'center', justifyContent: 'center',
            marginRight: 8, flexShrink: 0,
          }}>
            <Ionicons name="sparkles" size={15} color={C.primary} />
          </View>
        )}
        <View style={{
          maxWidth: '75%', borderRadius: 18, paddingHorizontal: 14, paddingVertical: 10,
          backgroundColor: isUser ? C.primary : C.surface,
          borderBottomRightRadius: isUser ? 4 : 18,
          borderBottomLeftRadius: isUser ? 18 : 4,
          shadowColor: '#000',
          shadowOpacity: isUser ? 0 : (C.background === '#000000' ? 0 : 0.04),
          shadowRadius: 6, shadowOffset: { width: 0, height: 1 },
          elevation: isUser ? 0 : 1,
        }}>
          <Text style={{
            fontSize: 15, lineHeight: 22,
            color: isUser ? '#FFFFFF' : C.textPrimary,
          }}>
            {item.content}
          </Text>
          <Text style={{
            fontSize: 11, marginTop: 4,
            color: isUser ? 'rgba(255,255,255,0.6)' : C.textMuted,
            textAlign: isUser ? 'right' : 'left',
          }}>
            {format(new Date(item.created_at), 'h:mm a')}
          </Text>
        </View>
      </View>
    );
  };

  if (initialLoad) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: C.background }}>
        <ActivityIndicator size="large" color={C.primary} />
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      style={{ flex: 1, backgroundColor: C.background }}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      keyboardVerticalOffset={Platform.OS === 'ios' ? 88 : 0}
    >
      {/* ── Header ── */}
      <View style={{
        flexDirection: 'row', alignItems: 'center', gap: 12,
        backgroundColor: C.surface,
        paddingTop: Platform.OS === 'ios' ? 56 : 20,
        paddingBottom: 14, paddingHorizontal: 20,
        borderBottomWidth: 0.5, borderBottomColor: C.separator,
      }}>
        <View style={{
          width: 42, height: 42, borderRadius: 13,
          backgroundColor: C.primary,
          alignItems: 'center', justifyContent: 'center',
        }}>
          <Ionicons name="sparkles" size={20} color="#FFFFFF" />
        </View>
        <View>
          <Text style={{ fontSize: 16, fontWeight: '700', color: C.textPrimary }}>AI Health Assistant</Text>
          <Text style={{ fontSize: 12, color: C.textMuted, marginTop: 1 }}>Ask me anything about IBD</Text>
        </View>
      </View>

      {initialLoadError && (
        <View style={{
          flexDirection: 'row', alignItems: 'center', gap: 6,
          backgroundColor: C.danger + '12',
          borderBottomWidth: 0.5, borderBottomColor: C.danger + '30',
          paddingHorizontal: 16, paddingVertical: 10,
        }}>
          <Ionicons name="alert-circle-outline" size={14} color={C.danger} />
          <Text style={{ color: C.danger, fontSize: 12, fontWeight: '600' }}>{initialLoadError}</Text>
        </View>
      )}

      {/* ── Empty State / Messages ── */}
      {messages.length === 0 && !loading ? (
        <View style={{ flex: 1, paddingHorizontal: 20, paddingTop: 32 }}>
          {/* Hero */}
          <View style={{ alignItems: 'center', marginBottom: 32 }}>
            <View style={{
              width: 76, height: 76, borderRadius: 24,
              backgroundColor: C.primary + '15',
              alignItems: 'center', justifyContent: 'center', marginBottom: 16,
            }}>
              <Ionicons name="sparkles" size={34} color={C.primary} />
            </View>
            <Text style={{ fontSize: 20, fontWeight: '700', color: C.textPrimary, marginBottom: 6 }}>
              Hi, I&apos;m your IBD Assistant
            </Text>
            <Text style={{ fontSize: 14, color: C.textSecondary, textAlign: 'center', lineHeight: 20 }}>
              I can help you understand your symptoms, medications, and health trends.
            </Text>
          </View>

          <Text style={{ fontSize: 13, fontWeight: '600', color: C.textMuted, marginBottom: 10, textTransform: 'uppercase', letterSpacing: 0.5 }}>
            Try asking
          </Text>
          {STARTER_QUESTIONS.map((q) => (
            <TouchableOpacity
              key={q}
              style={{
                flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
                backgroundColor: C.surface, borderRadius: 14,
                paddingHorizontal: 16, paddingVertical: 14, marginBottom: 8,
                shadowColor: '#000',
                shadowOpacity: C.background === '#000000' ? 0 : 0.04,
                shadowRadius: 6, shadowOffset: { width: 0, height: 1 },
                elevation: 1,
              }}
              onPress={() => sendMessage(q)}
              activeOpacity={0.7}
            >
              <Text style={{ flex: 1, fontSize: 14, color: C.primary, fontWeight: '500', marginRight: 8 }}>
                {q}
              </Text>
              <Ionicons name="arrow-forward-outline" size={14} color={C.primary} />
            </TouchableOpacity>
          ))}
        </View>
      ) : (
        <FlatList
          ref={flatListRef}
          data={messages}
          keyExtractor={(item) => item.id}
          renderItem={renderMessage}
          contentContainerStyle={{ paddingHorizontal: 16, paddingVertical: 12 }}
          showsVerticalScrollIndicator={false}
          onContentSizeChange={() => flatListRef.current?.scrollToEnd({ animated: true })}
          ListFooterComponent={
            loading ? (
              <View style={{
                flexDirection: 'row', marginBottom: 12, alignItems: 'flex-end',
              }}>
                <View style={{
                  width: 32, height: 32, borderRadius: 10,
                  backgroundColor: C.primary + '18',
                  alignItems: 'center', justifyContent: 'center', marginRight: 8,
                }}>
                  <Ionicons name="sparkles" size={15} color={C.primary} />
                </View>
                <View style={{
                  backgroundColor: C.surface, borderRadius: 18, borderBottomLeftRadius: 4,
                  paddingHorizontal: 18, paddingVertical: 14,
                }}>
                  <ActivityIndicator size="small" color={C.textMuted} />
                </View>
              </View>
            ) : null
          }
        />
      )}

      {/* ── Input Row ── */}
      <View style={{
        flexDirection: 'row', alignItems: 'flex-end', gap: 10,
        paddingHorizontal: 16, paddingVertical: 12,
        backgroundColor: C.surface,
        borderTopWidth: 0.5, borderTopColor: C.separator,
      }}>
        <TextInput
          style={{
            flex: 1, backgroundColor: C.background, borderRadius: 22,
            paddingHorizontal: 16, paddingVertical: Platform.OS === 'ios' ? 10 : 8,
            fontSize: 15, color: C.textPrimary,
            borderWidth: 1, borderColor: C.border, maxHeight: 120,
          }}
          value={input}
          onChangeText={setInput}
          placeholder="Ask me anything..."
          placeholderTextColor={C.placeholder}
          multiline
          maxLength={1000}
        />
        <TouchableOpacity
          style={{
            width: 42, height: 42, borderRadius: 21,
            backgroundColor: (!input.trim() || sending || loading) ? C.border : C.primary,
            alignItems: 'center', justifyContent: 'center',
            shadowColor: C.primary, shadowOpacity: (!input.trim() || sending || loading) ? 0 : 0.35,
            shadowRadius: 6, shadowOffset: { width: 0, height: 3 },
            elevation: (!input.trim() || sending || loading) ? 0 : 4,
          }}
          onPress={() => sendMessage(input)}
          disabled={!input.trim() || sending || loading}
          activeOpacity={0.8}
        >
          {sending
            ? <ActivityIndicator size="small" color="#FFFFFF" />
            : <Ionicons name="arrow-up" size={20} color="#FFFFFF" />}
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}
