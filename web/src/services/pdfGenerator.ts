import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import dayjs from 'dayjs';
import { InvoiceFormValues } from '../types/invoice';

function calculateAmounts(invoice: InvoiceFormValues) {
  const subtotal = invoice.items.reduce((sum, item) => sum + item.quantity * item.unitPrice, 0);
  const tax = Math.round(subtotal * (invoice.taxRate / 100));
  const total = subtotal + tax;
  return { subtotal, tax, total };
}

export function downloadInvoice(invoice: InvoiceFormValues) {
  const doc = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(20);
  doc.text('請求書', 105, 25, { align: 'center' });

  doc.setFontSize(10);
  doc.setFont('helvetica', 'normal');
  doc.text(`発行日: ${dayjs(invoice.issueDate).format('YYYY年MM月DD日')}`, 20, 40);
  doc.text(`請求書番号: ${invoice.invoiceNumber}`, 20, 46);

  doc.setFontSize(11);
  doc.text(invoice.clientName, 20, 60);
  doc.text(invoice.clientAddress, 20, 66);

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(16);
  const { subtotal, tax, total } = calculateAmounts(invoice);
  doc.text(`請求金額: ¥${total.toLocaleString()}`, 105, 80, { align: 'center' });

  doc.setFontSize(11);
  doc.setFont('helvetica', 'normal');
  doc.text('貴社ますますご清栄のこととお喜び申し上げます。下記の通りご請求申し上げます。', 20, 90);

  autoTable(doc, {
    startY: 100,
    head: [['品目', '数量', '単価', '金額']],
    body: invoice.items.map((item) => [
      item.name,
      `${item.quantity.toLocaleString()}`,
      `¥${item.unitPrice.toLocaleString()}`,
      `¥${(item.quantity * item.unitPrice).toLocaleString()}`
    ]),
    headStyles: { fillColor: [31, 80, 154] },
    bodyStyles: { halign: 'right' },
    columnStyles: {
      0: { halign: 'left' }
    }
  });

  const summaryStart = (doc as any).lastAutoTable.finalY + 10;
  doc.text(`小計: ¥${subtotal.toLocaleString()}`, 150, summaryStart, { align: 'right' });
  doc.text(`消費税 (${invoice.taxRate}%): ¥${tax.toLocaleString()}`, 150, summaryStart + 6, { align: 'right' });
  doc.setFont('helvetica', 'bold');
  doc.text(`合計: ¥${total.toLocaleString()}`, 150, summaryStart + 16, { align: 'right' });
  doc.setFont('helvetica', 'normal');

  if (invoice.notes) {
    doc.text('備考:', 20, summaryStart + 28);
    doc.text(doc.splitTextToSize(invoice.notes, 170), 20, summaryStart + 34);
  }

  if (invoice.stampNeeded) {
    doc.setDrawColor(0);
    doc.rect(160, 40, 25, 25);
    doc.text('収入印紙', 172.5, 53, { align: 'center' });
  }

  doc.setFontSize(10);
  doc.text(invoice.companyName, 190, 40, { align: 'right' });
  doc.text(invoice.companyAddress, 190, 46, { align: 'right' });
  if (invoice.companyPhone) {
    doc.text(`TEL: ${invoice.companyPhone}`, 190, 52, { align: 'right' });
  }

  doc.save(`invoice-${invoice.invoiceNumber}.pdf`);
}
