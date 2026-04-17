import { Tabs } from 'expo-router';
import { Platform, View } from 'react-native';
import { BlurView } from 'expo-blur';
import { LinearGradient } from 'expo-linear-gradient';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { AppIcon } from '../../components/ui/DesignPrimitives';
import { useColors } from '../../constants/colors';
import { selectionHaptic } from '../../lib/haptics';

function GlassTabBarBackground() {
  const C = useColors();
  return (
    <View
      style={{
        flex: 1,
        overflow: 'hidden',
        borderRadius: 26,
        borderCurve: 'continuous',
        backgroundColor: Platform.OS === 'ios' ? 'transparent' : C.navGlass,
      }}
    >
      {Platform.OS === 'ios' ? (
        <BlurView
          intensity={70}
          tint={C.isDark ? 'systemChromeMaterialDark' : 'systemChromeMaterialLight'}
          style={{ flex: 1 }}
        />
      ) : (
        <View style={{ flex: 1, backgroundColor: C.navGlass }} />
      )}
      <LinearGradient
        colors={[C.glassHighlight, 'transparent']}
        start={{ x: 0.5, y: 0 }}
        end={{ x: 0.5, y: 1 }}
        style={{ position: 'absolute', top: 0, left: 0, right: 0, height: '45%', opacity: 0.24 }}
      />
      <View
        pointerEvents="none"
        style={{
          position: 'absolute',
          inset: 0,
          borderRadius: 26,
          borderCurve: 'continuous',
          borderWidth: 1,
          borderColor: C.glassBorder,
        }}
      />
    </View>
  );
}

export default function TabsLayout() {
  const C = useColors();
  const insets = useSafeAreaInsets();

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: C.primary,
        tabBarInactiveTintColor: C.textMuted,
        tabBarStyle: {
          position: 'absolute',
          borderTopWidth: 0,
          backgroundColor: 'transparent',
          height: 68 + Math.max(insets.bottom, 12),
          paddingBottom: Math.max(insets.bottom, 12),
          paddingTop: 10,
          marginHorizontal: 12,
          marginBottom: 10,
          borderRadius: 26,
          shadowColor: '#000000',
          shadowOpacity: C.isDark ? 0.28 : 0.12,
          shadowRadius: 28,
          shadowOffset: { width: 0, height: 14 },
          elevation: 10,
        },
        tabBarBackground: () => <GlassTabBarBackground />,
        tabBarLabelStyle: {
          fontSize: 11,
          fontWeight: '600',
          letterSpacing: -0.08,
        },
        tabBarItemStyle: {
          borderRadius: 18,
        },
      }}
    >
      <Tabs.Screen
        name="home"
        listeners={{ tabPress: () => selectionHaptic() }}
        options={{
          title: 'Home',
          tabBarIcon: ({ focused, color }) => (
            <AppIcon
              symbol={focused ? 'house.fill' : 'house'}
              fallback={focused ? 'home' : 'home-outline'}
              tintColor={color}
              size={21}
              selected={focused}
            />
          ),
        }}
      />
      <Tabs.Screen
        name="log"
        listeners={{ tabPress: () => selectionHaptic() }}
        options={{
          title: 'Log',
          tabBarIcon: ({ focused, color }) => (
            <AppIcon
              symbol={focused ? 'plus.circle.fill' : 'plus.circle'}
              fallback={focused ? 'add-circle' : 'add-circle-outline'}
              tintColor={color}
              size={23}
              selected={focused}
            />
          ),
        }}
      />
      <Tabs.Screen
        name="insights"
        listeners={{ tabPress: () => selectionHaptic() }}
        options={{
          title: 'Insights',
          tabBarIcon: ({ focused, color }) => (
            <AppIcon
              symbol={focused ? 'chart.bar.fill' : 'chart.bar'}
              fallback={focused ? 'bar-chart' : 'bar-chart-outline'}
              tintColor={color}
              size={21}
              selected={focused}
            />
          ),
        }}
      />
      <Tabs.Screen
        name="chat"
        listeners={{ tabPress: () => selectionHaptic() }}
        options={{
          title: 'AI Chat',
          tabBarIcon: ({ focused, color }) => (
            <AppIcon
              symbol={focused ? 'bubble.left.and.bubble.right.fill' : 'bubble.left.and.bubble.right'}
              fallback={focused ? 'chatbubble-ellipses' : 'chatbubble-ellipses-outline'}
              tintColor={color}
              size={21}
              selected={focused}
            />
          ),
        }}
      />
      <Tabs.Screen
        name="profile"
        listeners={{ tabPress: () => selectionHaptic() }}
        options={{
          title: 'Profile',
          tabBarIcon: ({ focused, color }) => (
            <AppIcon
              symbol={focused ? 'person.crop.circle.fill' : 'person.crop.circle'}
              fallback={focused ? 'person-circle' : 'person-circle-outline'}
              tintColor={color}
              size={24}
              selected={focused}
            />
          ),
        }}
      />
    </Tabs>
  );
}
