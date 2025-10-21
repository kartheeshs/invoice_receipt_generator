import {
  Box,
  Button,
  Container,
  Grid,
  Paper,
  Stack,
  Typography
} from '@mui/material';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import LoginIcon from '@mui/icons-material/Login';
import { useAuth } from '../contexts/AuthContext';

const featureList = [
  '日本語レイアウトに最適化された請求書テンプレート',
  '3件まで無料でPDFダウンロード',
  'クラウド保存でいつでも再利用',
  'プレミアムで無制限ダウンロードとカスタムロゴ対応'
];

export default function LoginPage() {
  const { signInWithGoogle } = useAuth();

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'linear-gradient(135deg, #eef2f7 0%, #dbe6f6 100%)'
      }}
    >
      <Container maxWidth="lg">
        <Grid container spacing={4} alignItems="center">
          <Grid item xs={12} md={6}>
            <Typography variant="h2" fontWeight={700} gutterBottom>
              和式請求書ジェネレーター
            </Typography>
            <Typography variant="h6" color="text.secondary" paragraph>
              フリーランスや個人事業主向けに設計された、美しく整った見積書・請求書・領収書を数分で作成できるツールです。
            </Typography>
            <Stack spacing={2} mt={4}>
              {featureList.map((feature) => (
                <Stack direction="row" spacing={2} alignItems="center" key={feature}>
                  <CheckCircleIcon color="primary" />
                  <Typography>{feature}</Typography>
                </Stack>
              ))}
            </Stack>
          </Grid>
          <Grid item xs={12} md={6}>
            <Paper elevation={8} sx={{ p: 5, borderRadius: 4 }}>
              <Typography variant="h5" fontWeight={600} mb={2}>
                無料で始めましょう
              </Typography>
              <Typography variant="body1" color="text.secondary" mb={4}>
                Googleアカウントでサインインすると、クラウド上に請求書を保存していつでも編集できます。
              </Typography>
              <Button
                size="large"
                variant="contained"
                fullWidth
                startIcon={<LoginIcon />}
                onClick={signInWithGoogle}
              >
                Googleでサインイン
              </Button>
              <Typography variant="caption" color="text.secondary" display="block" mt={2}>
                サインインすることで利用規約とプライバシーポリシーに同意したとみなします。
              </Typography>
            </Paper>
          </Grid>
        </Grid>
      </Container>
    </Box>
  );
}
