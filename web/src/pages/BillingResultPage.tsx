import { useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { Box, Button, Paper, Typography } from '@mui/material';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import ErrorOutlineIcon from '@mui/icons-material/ErrorOutline';
import { useSubscription } from '../contexts/SubscriptionContext';

export default function BillingResultPage() {
  const { status } = useParams();
  const navigate = useNavigate();
  const { refresh } = useSubscription();

  const isSuccess = status === 'success';

  useEffect(() => {
    if (isSuccess) {
      void refresh();
    }
  }, [isSuccess, refresh]);

  return (
    <Box display="flex" justifyContent="center" alignItems="center" minHeight="60vh">
      <Paper sx={{ p: 6, borderRadius: 4, textAlign: 'center', maxWidth: 480 }} elevation={6}>
        {isSuccess ? (
          <CheckCircleIcon color="success" sx={{ fontSize: 64 }} />
        ) : (
          <ErrorOutlineIcon color="error" sx={{ fontSize: 64 }} />
        )}
        <Typography variant="h4" fontWeight={700} mt={2} gutterBottom>
          {isSuccess ? 'ご利用ありがとうございます' : '手続きが完了しませんでした'}
        </Typography>
        <Typography variant="body1" color="text.secondary" mb={4}>
          {isSuccess
            ? 'プレミアムプランのご契約が完了しました。すべての機能をご利用いただけます。'
            : '決済がキャンセルされたか失敗しました。再度お試しください。'}
        </Typography>
        <Button variant="contained" onClick={() => navigate('/')}>ダッシュボードに戻る</Button>
      </Paper>
    </Box>
  );
}
