import React from 'react';
import { ActivityIndicator, View, Text, ScrollView, TouchableOpacity, StyleSheet } from 'react-native';
import { NavigationContainer, useNavigationState } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { useAuth } from '../context/AuthContext';

import LoginScreen from '../screens/LoginScreen';
import RegisterScreen from '../screens/RegisterScreen';
import ForgotPasswordScreen from '../screens/ForgotPasswordScreen';
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

import CatalogosHomeScreen from '../screens/CatalogosHomeScreen';
import CatalogListScreen from '../screens/CatalogListScreen';
import CatalogFormScreen from '../screens/CatalogFormScreen';

import RootPanelScreen from '../screens/RootPanelScreen';
import EmpresasScreen from '../screens/EmpresasScreen';
import EmpresaFormScreen from '../screens/EmpresaFormScreen';
import EmpresaDetalleScreen from '../screens/EmpresaDetalleScreen';
import AprobacionUsuariosScreen from '../screens/AprobacionUsuariosScreen';
import ReportesGlobalesScreen from '../screens/ReportesGlobalesScreen';

import OrdenesClienteListScreen from '../screens/OrdenesClienteListScreen';
import OrdenClienteFormScreen from '../screens/OrdenClienteFormScreen';
import OrdenClienteDetalleScreen from '../screens/OrdenClienteDetalleScreen';
import ComprasClienteListScreen from '../screens/ComprasClienteListScreen';
import CompraClienteFormScreen from '../screens/CompraClienteFormScreen';
import CompraClienteDetalleScreen from '../screens/CompraClienteDetalleScreen';
import ComprasInsumoListScreen from '../screens/ComprasInsumoListScreen';
import ComprasInsumoFormScreen from '../screens/ComprasInsumoFormScreen';
import ComprasInsumoDetalleScreen from '../screens/ComprasInsumoDetalleScreen';

const Stack = createNativeStackNavigator();
const Tab = createBottomTabNavigator();

const screenOptions = {
  headerStyle: { backgroundColor: Colors.card },
  headerTintColor: Colors.primary,
  headerTitleStyle: { color: Colors.text, fontWeight: '600' },
  headerShadowVisible: false,
  headerBackTitleVisible: false,
};

function NavMenuScreen({ navigation, items }) {
  return (
    <ScrollView style={navStyles.container} contentContainerStyle={navStyles.content}>
      <View style={navStyles.card}>
        {items.map((item, i) => (
          <React.Fragment key={item.key}>
            {i > 0 && <View style={navStyles.divider} />}
            <TouchableOpacity
              style={navStyles.row}
              activeOpacity={0.6}
              onPress={() => navigation.navigate(item.key)}
            >
              <View style={navStyles.rowLeft}>
                <View style={[navStyles.iconBadge, { backgroundColor: item.color + '20' }]}>
                  <Ionicons name={item.icon} size={20} color={item.color} />
                </View>
                <View style={navStyles.rowTexts}>
                  <Text style={navStyles.rowLabel}>{item.label}</Text>
                  <Text style={navStyles.rowDesc}>{item.description}</Text>
                </View>
              </View>
              <Ionicons name="chevron-forward" size={18} color={Colors.textTertiary} />
            </TouchableOpacity>
          </React.Fragment>
        ))}
      </View>
    </ScrollView>
  );
}

const navStyles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background },
  content: { padding: Spacing.md },
  card: { backgroundColor: Colors.card, borderRadius: BorderRadius.lg, paddingHorizontal: Spacing.md },
  divider: { height: 1, backgroundColor: Colors.separator },
  row: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingVertical: 14 },
  rowLeft: { flexDirection: 'row', alignItems: 'center', flex: 1 },
  iconBadge: { width: 36, height: 36, borderRadius: 10, alignItems: 'center', justifyContent: 'center', marginRight: 12 },
  rowTexts: { flex: 1 },
  rowLabel: { fontSize: FontSize.body, color: Colors.text },
  rowDesc: { fontSize: FontSize.caption, color: Colors.textSecondary, marginTop: 2 },
});

function ComprasHomeScreen({ navigation }) {
  return (
    <NavMenuScreen
      navigation={navigation}
      items={[
        { key: 'ComprasClienteList', label: 'Compras de Cliente', icon: 'people-outline', description: 'Órdenes de compra a proveedores', color: Colors.teal },
        { key: 'ComprasInsumoList', label: 'Compras de Insumo', icon: 'cube-outline', description: 'Compras de materiales e insumos', color: Colors.orange },
      ]}
    />
  );
}

function VentasStack() {
  return (
    <Stack.Navigator screenOptions={screenOptions}>
      <Stack.Screen name="OrdenesClienteList" component={OrdenesClienteListScreen} options={{ title: 'Órdenes de Cliente' }} />
      <Stack.Screen name="OrdenClienteForm" component={OrdenClienteFormScreen} options={({ route }) => ({ title: route.params?.orden ? 'Editar Orden' : 'Nueva Orden' })} />
      <Stack.Screen name="OrdenClienteDetalle" component={OrdenClienteDetalleScreen} options={{ title: 'Detalle de Orden' }} />
    </Stack.Navigator>
  );
}

function ComprasStack() {
  return (
    <Stack.Navigator screenOptions={screenOptions}>
      <Stack.Screen name="ComprasHome" component={ComprasHomeScreen} options={{ title: 'Compras' }} />
      <Stack.Screen name="ComprasClienteList" component={ComprasClienteListScreen} options={{ title: 'Compras de Cliente' }} />
      <Stack.Screen name="CompraClienteForm" component={CompraClienteFormScreen} options={({ route }) => ({ title: route.params?.id ? 'Editar Compra' : 'Nueva Compra' })} />
      <Stack.Screen name="CompraClienteDetalle" component={CompraClienteDetalleScreen} options={{ title: 'Detalle de Compra' }} />
      <Stack.Screen name="ComprasInsumoList" component={ComprasInsumoListScreen} options={{ title: 'Compras de Insumo' }} />
      <Stack.Screen name="ComprasInsumoForm" component={ComprasInsumoFormScreen} options={({ route }) => ({ title: route.params?.id ? 'Editar Compra' : 'Nueva Compra' })} />
      <Stack.Screen name="ComprasInsumoDetalle" component={ComprasInsumoDetalleScreen} options={{ title: 'Detalle de Compra' }} />
    </Stack.Navigator>
  );
}

function AdminStack() {
  return (
    <Stack.Navigator screenOptions={screenOptions}>
      <Stack.Screen name="AdminHome" component={AdminScreen} options={{ title: 'Administración' }} />
      <Stack.Screen name="UsuariosScreen" component={UsuariosScreen} options={{ title: 'Usuarios' }} />
      <Stack.Screen name="UsuarioDetalle" component={UsuarioDetalleScreen} options={{ title: 'Detalle' }} />
      <Stack.Screen name="CrearUsuario" component={CrearUsuarioScreen} options={{ title: 'Nuevo Usuario' }} />
      <Stack.Screen name="RolesScreen" component={RolesScreen} options={{ title: 'Roles' }} />
      <Stack.Screen name="RolForm" component={RolFormScreen} options={({ route }) => ({ title: route.params?.rol ? 'Editar Rol' : 'Nuevo Rol' })} />
      <Stack.Screen name="CatalogosHome" component={CatalogosHomeScreen} options={{ title: 'Catálogos' }} />
      <Stack.Screen name="CatalogList" component={CatalogListScreen} options={({ route }) => ({ title: route.params?.title || 'Catálogo' })} />
      <Stack.Screen name="CatalogForm" component={CatalogFormScreen} options={({ route }) => ({ title: route.params?.item ? `Editar` : 'Nuevo' })} />
      <Stack.Screen name="PerfilScreen" component={ProfileScreen} options={{ title: 'Mi Perfil' }} />
    </Stack.Navigator>
  );
}

function RootStack() {
  return (
    <Stack.Navigator screenOptions={screenOptions}>
      <Stack.Screen name="RootHome" component={RootPanelScreen} options={{ title: 'Panel Root' }} />
      <Stack.Screen name="EmpresasScreen" component={EmpresasScreen} options={{ title: 'Empresas' }} />
      <Stack.Screen name="EmpresaForm" component={EmpresaFormScreen} options={({ route }) => ({ title: route.params?.empresa ? 'Editar Empresa' : 'Nueva Empresa' })} />
      <Stack.Screen name="EmpresaDetalle" component={EmpresaDetalleScreen} options={{ title: 'Detalle Empresa' }} />
      <Stack.Screen name="AprobacionUsuarios" component={AprobacionUsuariosScreen} options={{ title: 'Usuarios Pendientes' }} />
      <Stack.Screen name="UsuariosGlobal" component={UsuariosScreen} options={{ title: 'Todos los Usuarios' }} />
      <Stack.Screen name="UsuarioDetalle" component={UsuarioDetalleScreen} options={{ title: 'Detalle' }} />
      <Stack.Screen name="CrearUsuario" component={CrearUsuarioScreen} options={{ title: 'Nuevo Usuario' }} />
      <Stack.Screen name="ReportesGlobales" component={ReportesGlobalesScreen} options={{ title: 'Reportes Globales' }} />
      <Stack.Screen name="PerfilScreen" component={ProfileScreen} options={{ title: 'Mi Perfil' }} />
    </Stack.Navigator>
  );
}

function HomeStack() {
  return (
    <Stack.Navigator screenOptions={screenOptions}>
      <Stack.Screen name="HomeMain" component={HomeScreen} options={{ title: 'Textil' }} />
    </Stack.Navigator>
  );
}

function OperacionStack() {
  return (
    <Stack.Navigator screenOptions={screenOptions}>
      <Stack.Screen name="OperacionHome" component={PlaceholderScreen} initialParams={{ title: 'Operación', icon: 'construct-outline', color: Colors.orange }} options={{ title: 'Operación' }} />
    </Stack.Navigator>
  );
}

function MainTabs() {
  const { user } = useAuth();

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
          else if (route.name === 'RootTab') iconName = focused ? 'shield-checkmark' : 'shield-checkmark-outline';
          return <Ionicons name={iconName} size={size} color={color} />;
        },
        tabBarActiveTintColor: Colors.primary,
        tabBarInactiveTintColor: Colors.textTertiary,
        tabBarStyle: { backgroundColor: Colors.card, borderTopColor: Colors.separator },
        headerShown: false,
      })}
    >
      <Tab.Screen name="HomeTab" component={HomeStack} options={{ title: 'Inicio' }} />
      <Tab.Screen name="OperacionTab" component={OperacionStack} options={{ title: 'Operación' }} />
      <Tab.Screen name="ComprasTab" component={ComprasStack} options={{ title: 'Compras' }}
        listeners={({ navigation }) => ({
          tabPress: (e) => { navigation.navigate('ComprasTab', { screen: 'ComprasHome' }); },
        })}
      />
      <Tab.Screen name="VentasTab" component={VentasStack} options={{ title: 'Ventas' }}
        listeners={({ navigation }) => ({
          tabPress: (e) => { navigation.navigate('VentasTab', { screen: 'OrdenesClienteList' }); },
        })}
      />
      <Tab.Screen name="AdminTab" component={AdminStack} options={{ title: 'Admin' }}
        listeners={({ navigation }) => ({
          tabPress: (e) => { navigation.navigate('AdminTab', { screen: 'AdminHome' }); },
        })}
      />
      {user?.es_root && (
        <Tab.Screen name="RootTab" component={RootStack} options={{ title: 'Root' }}
          listeners={({ navigation }) => ({
            tabPress: (e) => { navigation.navigate('RootTab', { screen: 'RootHome' }); },
          })}
        />
      )}
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
          <>
            <Stack.Screen name="Login" component={LoginScreen} />
            <Stack.Screen name="Register" component={RegisterScreen} options={{ headerShown: false }} />
            <Stack.Screen name="ForgotPassword" component={ForgotPasswordScreen} options={{ headerShown: false }} />
          </>
        ) : (!user.activo || !user.aprobado) ? (
          <Stack.Screen name="Blocked" component={BlockedScreen} />
        ) : (
          <Stack.Screen name="Main" component={MainTabs} />
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
}
