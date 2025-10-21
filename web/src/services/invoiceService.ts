import dayjs from 'dayjs';
import {
  addDoc,
  collection,
  doc,
  firestore,
  getDoc,
  getDocs,
  orderBy,
  query,
  setDoc
} from './firebase';
import { InvoiceFormValues, InvoiceRecord } from '../types/invoice';

const COLLECTION_KEY = 'invoices';

export async function saveInvoice(userId: string, values: InvoiceFormValues): Promise<InvoiceRecord> {
  const now = dayjs().toISOString();
  const payload: InvoiceRecord = {
    ...values,
    id: values.id,
    userId,
    createdAt: values.createdAt ?? now,
    updatedAt: now
  } as InvoiceRecord;

  const userCollection = collection(firestore, 'users', userId, COLLECTION_KEY);

  if (values.id) {
    const docRef = doc(userCollection, values.id);
    await setDoc(docRef, payload, { merge: true });
    return { ...payload, id: values.id };
  }

  const createdDoc = await addDoc(userCollection, payload);
  const storedPayload = { ...payload, id: createdDoc.id };
  await setDoc(createdDoc, storedPayload, { merge: true });
  return storedPayload;
}

export async function getInvoice(userId: string, invoiceId: string) {
  const invoiceRef = doc(firestore, 'users', userId, COLLECTION_KEY, invoiceId);
  const snapshot = await getDoc(invoiceRef);
  return snapshot.exists() ? (snapshot.data() as InvoiceRecord) : undefined;
}

export async function listInvoices(userId: string) {
  const invoiceCollection = collection(firestore, 'users', userId, COLLECTION_KEY);
  const q = query(invoiceCollection, orderBy('issueDate', 'desc'));
  const snapshot = await getDocs(q);
  return snapshot.docs.map((docSnap) => docSnap.data() as InvoiceRecord);
}
