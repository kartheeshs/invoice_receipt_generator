import {
  AppBar,
  Avatar,
  Box,
  Button,
  Divider,
  Drawer,
  IconButton,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Toolbar,
  Typography
} from '@mui/material';
import MenuIcon from '@mui/icons-material/Menu';
import DashboardIcon from '@mui/icons-material/Dashboard';
import ReceiptLongIcon from '@mui/icons-material/ReceiptLong';
import SettingsIcon from '@mui/icons-material/Settings';
import WorkspacePremiumIcon from '@mui/icons-material/WorkspacePremium';
import { Outlet, useLocation, useNavigate } from 'react-router-dom';
import { PropsWithChildren, useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useSubscription } from '../contexts/SubscriptionContext';

const drawerWidth = 240;

const navigationItems = [
  { label: 'ダッシュボード', icon: <DashboardIcon />, path: '/' },
  { label: '請求書一覧', icon: <ReceiptLongIcon />, path: '/invoices' },
  { label: '設定', icon: <SettingsIcon />, path: '/settings' }
];

function DrawerContent({ onNavigate }: { onNavigate: () => void }) {
  const location = useLocation();
  const navigate = useNavigate();

  return (
    <Box sx={{ textAlign: 'center' }}>
      <Typography variant="h6" sx={{ my: 2, fontWeight: 700 }}>
        和式請求書
      </Typography>
      <Divider />
      <List>
        {navigationItems.map((item) => (
          <ListItem key={item.path} disablePadding>
            <ListItemButton
              selected={
                item.path === '/'
                  ? location.pathname === '/'
                  : location.pathname.startsWith(item.path)
              }
              onClick={() => {
                navigate(item.path);
                onNavigate();
              }}
            >
              <ListItemIcon>{item.icon}</ListItemIcon>
              <ListItemText primary={item.label} />
            </ListItemButton>
          </ListItem>
        ))}
      </List>
    </Box>
  );
}

export default function DashboardLayout({ children }: PropsWithChildren) {
  const { user, signOutUser } = useAuth();
  const { subscription } = useSubscription();
  const [mobileOpen, setMobileOpen] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();

  const handleDrawerToggle = () => {
    setMobileOpen((prev) => !prev);
  };

  const drawer = <DrawerContent onNavigate={() => setMobileOpen(false)} />;

  return (
    <Box sx={{ display: 'flex' }}>
      <AppBar
        position="fixed"
        sx={{
          width: { sm: `calc(100% - ${drawerWidth}px)` },
          ml: { sm: `${drawerWidth}px` },
          background: 'linear-gradient(90deg, #1f509a 0%, #274d8a 100%)'
        }}
      >
        <Toolbar>
          <IconButton
            color="inherit"
            aria-label="open drawer"
            edge="start"
            onClick={handleDrawerToggle}
            sx={{ mr: 2, display: { sm: 'none' } }}
          >
            <MenuIcon />
          </IconButton>
          <Box sx={{ flexGrow: 1 }}>
            <Typography variant="h6" noWrap component="div">
              プロフェッショナル請求書メーカー
            </Typography>
            <Typography variant="caption" sx={{ opacity: 0.8 }}>
              {subscription?.plan === 'premium' ? 'プレミアムプラン' : '無料プラン'}
            </Typography>
          </Box>
          {subscription?.plan !== 'premium' && (
            <Button
              color="secondary"
              variant="contained"
              startIcon={<WorkspacePremiumIcon />}
              onClick={() => navigate('/settings#billing')}
              sx={{ mr: 2 }}
            >
              プレミアムにアップグレード
            </Button>
          )}
          <Button color="inherit" onClick={signOutUser}>
            ログアウト
          </Button>
          <Avatar sx={{ ml: 2, bgcolor: '#f1b722', color: '#123' }} src={user?.photoURL ?? undefined}>
            {user?.displayName?.[0] ?? 'U'}
          </Avatar>
        </Toolbar>
      </AppBar>
      <Box component="nav" sx={{ width: { sm: drawerWidth }, flexShrink: { sm: 0 } }} aria-label="navigation">
        <Drawer
          variant="temporary"
          open={mobileOpen}
          onClose={handleDrawerToggle}
          ModalProps={{
            keepMounted: true
          }}
          sx={{
            display: { xs: 'block', sm: 'none' },
            '& .MuiDrawer-paper': { boxSizing: 'border-box', width: drawerWidth }
          }}
        >
          {drawer}
        </Drawer>
        <Drawer
          variant="permanent"
          sx={{
            display: { xs: 'none', sm: 'block' },
            '& .MuiDrawer-paper': { boxSizing: 'border-box', width: drawerWidth }
          }}
          open
        >
          {drawer}
        </Drawer>
      </Box>
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          p: 3,
          width: { sm: `calc(100% - ${drawerWidth}px)` },
          backgroundColor: '#f7f8fa',
          minHeight: '100vh'
        }}
      >
        <Toolbar />
        <Box sx={{ maxWidth: 1200, margin: '0 auto', width: '100%' }}>
          {children ?? <Outlet key={location.pathname} />}
        </Box>
      </Box>
    </Box>
  );
}
