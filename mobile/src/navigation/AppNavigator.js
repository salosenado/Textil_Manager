import React from 'react';
import { ActivityIndicator, View } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';
import { Colors, FontSize } from '../theme';
import { useAuth } from '../context/AuthContext';

import LoginScreen from '../screens/LoginScreen';
import BlockedScreen from '../screens/BlockedScreen';
import HomeScreen from '../screens/HomeScreen';
import PlaceholderScreen from '../screens/PlaceholderScreen';
import AdminScreen from '../screens/AdminScreen';
import ProfileScreen from '../screens/ProfileScreen';
import UsuariosScreen from '../screens/UsuariosScreen';
import UsuarioDetalleScreen from '../screens/UsuarioDetalleScreen';
import CrearUsuarioScreen from '../screens/CrearUsuarioScreen';
import RolesScreen from '../screens/RolesScreen';
import RolFormScreen from '../screens/RolFormScreen';

const Stack = createNativeStackNavigator();
const Tab = createBottomTabNavigator();

const screenOptions = {
  headerStyle: { backgroundColor: Colors.card },
  headerTintColor: Colors.primary,
  headerTitleStyle: { color: Colors.text, fontWeight: '600' },
  headerShadowVisible: false,
  headerBackTitleVisible: false,
};

function AdminStack() {
  return (
    <Stack.Navigator screenOptions={screenOptions}>
      <Stack.Screen name="AdminHome" component={AdminScreen} options={{ title: 'Administración' }} />
      <Stack.Screen name="UsuariosScreen" component={UsuariosScreen} options={{ title: 'Usuarios' }} />
      <Stack.Screen name="UsuarioDetalle" component={UsuarioDetalleScreen} options={{ title: 'Detalle' }} />
      <Stack.Screen name="CrearUsuario" component={CrearUsuarioScreen} options={{ title: 'Nuevo Usuario' }} />
      <Stack.Screen name="RolesScreen" component={RolesScreen} options={{ title: 'Roles' }} />
      <Stack.Screen name="RolForm" component={RolFormScreen} options={({ route }) => ({ title: route.params?.rol ? 'Editar Rol' : 'Nuevo Rol' })} />
      <Stack.Screen name="PerfilScreen" component={ProfileScreen} options={{ title: 'Mi Perfil' }} />
    </Stack.Navigator>
  );
}

function MainTabs() {
  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ focused, color, size }) => {
          let iconName;
          if (route.name === 'HomeTab') iconName = focused ? 'home' : 'home-outline';
          else if (route.name === 'OperacionTab') iconName = focused ? 'construct' : 'construct-outline';
          else if (route.name === 'ComprasTab') iconName = focused ? 'bag' : 'bag-outline';
          else if (route.name === 'VentasTab') iconName = focused ? 'cart' : 'cart-outline';
          else if (route.name === 'AdminTab') iconName = focused ? 'settings' : 'settings-outline';
          return <Ionicons name={iconName} size={size} color={color} />;
        },
        tabBarActiveTintColor: Colors.primary,
        tabBarInactiveTintColor: Colors.textTertiary,
        tabBarStyle: { backgroundColor: Colors.card, borderTopColor: Colors.separator },
        headerShown: false,
      })}
    >
      <Tab.Screen
        name="HomeTab"
        component={HomeScreen}
        options={{ title: 'Inicio', headerShown: true, headerTitle: 'Textil', ...screenOptions }}
      />
      <Tab.Screen
        name="OperacionTab"
        component={PlaceholderScreen}
        initialParams={{ title: 'Operación', icon: 'construct-outline', color: Colors.orange }}
        options={{ title: 'Operación', headerShown: true, headerTitle: 'Operación', ...screenOptions }}
      />
      <Tab.Screen
        name="ComprasTab"
        component={PlaceholderScreen}
        initialParams={{ title: 'Compras', icon: 'bag-outline', color: Colors.teal }}
        options={{ title: 'Compras', headerShown: true, headerTitle: 'Compras', ...screenOptions }}
      />
      <Tab.Screen
        name="VentasTab"
        component={PlaceholderScreen}
        initialParams={{ title: 'Ventas', icon: 'cart-outline', color: Colors.purple }}
        options={{ title: 'Ventas', headerShown: true, headerTitle: 'Ventas', ...screenOptions }}
      />
      <Tab.Screen name="AdminTab" component={AdminStack} options={{ title: 'Admin' }} />
    </Tab.Navigator>
  );
}

export default function AppNavigator() {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: Colors.background }}>
        <ActivityIndicator size="large" color={Colors.primary} />
      </View>
    );
  }

  return (
    <NavigationContainer>
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        {!user ? (
          <Stack.Screen name="Login" component={LoginScreen} />
        ) : (!user.activo || !user.aprobado) ? (
          <Stack.Screen name="Blocked" component={BlockedScreen} />
        ) : (
          <Stack.Screen name="Main" component={MainTabs} />
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
}
