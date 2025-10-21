import {
  Box,
  Button,
  Card,
  CardContent,
  FormControlLabel,
  Grid,
  IconButton,
  InputAdornment,
  Switch,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Typography
} from '@mui/material';
import DeleteIcon from '@mui/icons-material/Delete';
import AddIcon from '@mui/icons-material/Add';
import { ChangeEvent } from 'react';
import { InvoiceFormValues, InvoiceItem } from '../types/invoice';
import { generateId } from '../utils/defaultInvoice';

type Props = {
  value: InvoiceFormValues;
  onChange: (value: InvoiceFormValues) => void;
};

function updateItem(items: InvoiceItem[], itemId: string, updater: (item: InvoiceItem) => InvoiceItem) {
  return items.map((item) => (item.id === itemId ? updater(item) : item));
}

export default function InvoiceForm({ value, onChange }: Props) {
  const handleFieldChange = (field: keyof InvoiceFormValues) => (event: ChangeEvent<HTMLInputElement>) => {
    onChange({ ...value, [field]: event.target.value });
  };

  const handleAddItem = () => {
    const newItems = [
      ...value.items,
      {
        id: generateId(),
        name: '',
        description: '',
        quantity: 1,
        unitPrice: 0
      }
    ];
    onChange({ ...value, items: newItems });
  };

  const handleRemoveItem = (itemId: string) => {
    if (value.items.length === 1) return;
    onChange({ ...value, items: value.items.filter((item) => item.id !== itemId) });
  };

  const handleItemChange = (itemId: string, field: keyof InvoiceItem, val: string) => {
    const updatedItems = updateItem(value.items, itemId, (item) => ({
      ...item,
      [field]: field === 'quantity' || field === 'unitPrice' ? Number(val) : val
    }));
    onChange({ ...value, items: updatedItems });
  };

  const subtotal = value.items.reduce((sum, item) => sum + item.quantity * item.unitPrice, 0);
  const tax = Math.round(subtotal * (value.taxRate / 100));
  const total = subtotal + tax;

  return (
    <Grid container spacing={3}>
      <Grid item xs={12} md={7}>
        <Card sx={{ borderRadius: 3 }}>
          <CardContent>
            <Typography variant="h6" fontWeight={600} mb={3}>
              会社情報
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={12}>
                <TextField
                  label="貴社名"
                  value={value.companyName}
                  onChange={handleFieldChange('companyName')}
                  fullWidth
                  required
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  label="住所"
                  value={value.companyAddress}
                  onChange={handleFieldChange('companyAddress')}
                  fullWidth
                  required
                />
              </Grid>
              <Grid item xs={12}>
                <TextField label="電話番号" value={value.companyPhone} onChange={handleFieldChange('companyPhone')} fullWidth />
              </Grid>
            </Grid>
          </CardContent>
        </Card>

        <Card sx={{ borderRadius: 3, mt: 3 }}>
          <CardContent>
            <Typography variant="h6" fontWeight={600} mb={3}>
              請求先情報
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={12}>
                <TextField
                  label="取引先名"
                  value={value.clientName}
                  onChange={handleFieldChange('clientName')}
                  fullWidth
                  required
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  label="住所"
                  value={value.clientAddress}
                  onChange={handleFieldChange('clientAddress')}
                  fullWidth
                  required
                />
              </Grid>
              <Grid item xs={6}>
                <TextField
                  label="請求書番号"
                  value={value.invoiceNumber}
                  onChange={handleFieldChange('invoiceNumber')}
                  fullWidth
                  required
                />
              </Grid>
              <Grid item xs={3}>
                <TextField
                  label="発行日"
                  type="date"
                  value={value.issueDate}
                  onChange={handleFieldChange('issueDate')}
                  fullWidth
                  InputLabelProps={{ shrink: true }}
                />
              </Grid>
              <Grid item xs={3}>
                <TextField
                  label="支払期日"
                  type="date"
                  value={value.dueDate}
                  onChange={handleFieldChange('dueDate')}
                  fullWidth
                  InputLabelProps={{ shrink: true }}
                />
              </Grid>
              <Grid item xs={4}>
                <TextField
                  label="税率 (%)"
                  type="number"
                  value={value.taxRate}
                  onChange={handleFieldChange('taxRate')}
                  fullWidth
                />
              </Grid>
              <Grid item xs={8} display="flex" alignItems="center">
                <FormControlLabel
                  control={<Switch checked={value.stampNeeded} onChange={(e) => onChange({ ...value, stampNeeded: e.target.checked })} />}
                  label="収入印紙枠を表示"
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  label="備考"
                  value={value.notes}
                  onChange={handleFieldChange('notes')}
                  fullWidth
                  multiline
                  minRows={3}
                />
              </Grid>
            </Grid>
          </CardContent>
        </Card>
      </Grid>

      <Grid item xs={12} md={5}>
        <Card sx={{ borderRadius: 3 }}>
          <CardContent>
            <Typography variant="h6" fontWeight={600} mb={2}>
              請求明細
            </Typography>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>品目</TableCell>
                  <TableCell align="right">数量</TableCell>
                  <TableCell align="right">単価</TableCell>
                  <TableCell align="right">削除</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {value.items.map((item) => (
                  <TableRow key={item.id}>
                    <TableCell width="45%">
                      <TextField
                        variant="standard"
                        fullWidth
                        value={item.name}
                        onChange={(event) => handleItemChange(item.id, 'name', event.target.value)}
                      />
                    </TableCell>
                    <TableCell align="right" width="15%">
                      <TextField
                        variant="standard"
                        type="number"
                        value={item.quantity}
                        onChange={(event) => handleItemChange(item.id, 'quantity', event.target.value)}
                        inputProps={{ min: 1 }}
                      />
                    </TableCell>
                    <TableCell align="right" width="25%">
                      <TextField
                        variant="standard"
                        type="number"
                        value={item.unitPrice}
                        onChange={(event) => handleItemChange(item.id, 'unitPrice', event.target.value)}
                        InputProps={{
                          startAdornment: <InputAdornment position="start">¥</InputAdornment>
                        }}
                      />
                    </TableCell>
                    <TableCell align="right" width="15%">
                      <IconButton onClick={() => handleRemoveItem(item.id)}>
                        <DeleteIcon />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
            <Button
              variant="text"
              startIcon={<AddIcon />}
              onClick={handleAddItem}
              sx={{ mt: 1 }}
            >
              明細行を追加
            </Button>
          </CardContent>
        </Card>

        <Card sx={{ borderRadius: 3, mt: 3 }}>
          <CardContent>
            <Typography variant="h6" fontWeight={600} mb={2}>
              金額概要
            </Typography>
            <Box display="flex" justifyContent="space-between" mb={1}>
              <Typography color="text.secondary">小計</Typography>
              <Typography>¥{subtotal.toLocaleString()}</Typography>
            </Box>
            <Box display="flex" justifyContent="space-between" mb={1}>
              <Typography color="text.secondary">消費税 ({value.taxRate}%)</Typography>
              <Typography>¥{tax.toLocaleString()}</Typography>
            </Box>
            <Box display="flex" justifyContent="space-between" fontWeight={700} fontSize="1.2rem">
              <Typography>合計</Typography>
              <Typography color="primary" fontWeight={700}>
                ¥{total.toLocaleString()}
              </Typography>
            </Box>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  );
}
