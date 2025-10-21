import { createTheme } from '@mui/material/styles';

const theme = createTheme({
  typography: {
    fontFamily: '"Noto Sans JP", sans-serif'
  },
  palette: {
    primary: {
      main: '#1f509a'
    },
    secondary: {
      main: '#f1b722'
    },
    background: {
      default: '#f7f8fa'
    }
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          textTransform: 'none',
          fontWeight: 600
        }
      }
    }
  }
});

export default theme;
