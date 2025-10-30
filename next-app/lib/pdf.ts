'use client';

type PdfImageResource = {
  name: string;
  data: Uint8Array;
  width: number;
  height: number;
};

type GenerateInvoicePdfOptions = {
  element: HTMLElement;
  scale?: number;
  margin?: number;
};

const PX_PER_INCH = 96;
const POINTS_PER_INCH = 72;

function pxToPt(px: number): number {
  return (px * POINTS_PER_INCH) / PX_PER_INCH;
}

function applyComputedStyles(source: Element, target: Element): void {
  const computed = window.getComputedStyle(source);
  let cssText = computed.cssText;
  if (!cssText) {
    cssText = Array.from(computed)
      .map((property) => {
        const value = computed.getPropertyValue(property);
        const priority = computed.getPropertyPriority(property);
        return `${property}: ${value}${priority ? ' !important' : ''};`;
      })
      .join(' ');
  }
  target.setAttribute('style', cssText);

  Array.from(source.children).forEach((child, index) => {
    const targetChild = target.children[index];
    if (targetChild) {
      applyComputedStyles(child, targetChild);
    }
  });
}

function cloneWithInlineStyles(element: HTMLElement, width: number, height: number): HTMLElement {
  const clone = element.cloneNode(true) as HTMLElement;
  applyComputedStyles(element, clone);
  clone.setAttribute('xmlns', 'http://www.w3.org/1999/xhtml');
  clone.style.width = `${width}px`;
  clone.style.height = `${height}px`;
  clone.style.boxSizing = 'border-box';
  return clone;
}

async function blobToDataUrl(blob: Blob): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      if (typeof reader.result === 'string') {
        resolve(reader.result);
      } else {
        reject(new Error('Failed to convert blob to data URL.'));
      }
    };
    reader.onerror = (event) => {
      reject(event);
    };
    reader.readAsDataURL(blob);
  });
}

async function fetchAsDataUrl(url: string): Promise<string | null> {
  if (typeof fetch !== 'function') {
    return null;
  }
  try {
    const response = await fetch(url, {
      mode: 'cors',
      credentials: 'omit',
    });
    if (!response.ok) {
      return null;
    }
    const blob = await response.blob();
    return await blobToDataUrl(blob);
  } catch (error) {
    console.warn('Unable to inline resource for PDF export.', error);
    return null;
  }
}

async function inlineExternalImages(root: HTMLElement): Promise<void> {
  const images = Array.from(root.querySelectorAll('img'));
  await Promise.all(
    images.map(async (image) => {
      const srcAttribute = image.getAttribute('src');
      const srcsetAttribute = image.getAttribute('srcset');

      function firstSrcFromSrcset(srcset: string | null): string | null {
        if (!srcset) {
          return null;
        }
        const [firstCandidate] = srcset.split(',');
        if (!firstCandidate) {
          return null;
        }
        const [url] = firstCandidate.trim().split(/\s+/);
        return url || null;
      }

      const source = srcAttribute || firstSrcFromSrcset(srcsetAttribute);
      if (!source || source.startsWith('data:')) {
        return;
      }
      const dataUrl = await fetchAsDataUrl(source);
      if (dataUrl) {
        image.setAttribute('src', dataUrl);
        image.removeAttribute('srcset');
        image.removeAttribute('sizes');
      } else {
        image.removeAttribute('src');
        image.removeAttribute('srcset');
        image.removeAttribute('sizes');
      }
    }),
  );
}

async function inlineBackgroundImages(root: HTMLElement): Promise<void> {
  const elements = [root, ...Array.from(root.querySelectorAll<HTMLElement>('*'))];
  await Promise.all(
    elements.map(async (element) => {
      const { style } = element;
      const backgroundImage = style.backgroundImage;
      const background = style.background;

      async function replaceUrls(value: string, setter: (next: string) => void) {
        if (!value || !value.includes('url(')) {
          return;
        }
        let nextValue = value;
        const urlPattern = /url\((['"]?)([^'"\)]+)\1\)/gi;
        const matches = Array.from(value.matchAll(urlPattern));
        for (const match of matches) {
          const [, , url] = match;
          if (!url || url.startsWith('data:')) {
            continue;
          }
          const dataUrl = await fetchAsDataUrl(url);
          if (dataUrl) {
            nextValue = nextValue.replace(match[0], `url("${dataUrl}")`);
          } else {
            nextValue = nextValue.replace(match[0], 'none');
          }
        }
        setter(nextValue);
      }

      await replaceUrls(backgroundImage, (next) => {
        style.backgroundImage = next;
      });

      await replaceUrls(background, (next) => {
        style.background = next;
      });
    }),
  );
}

function loadSvgImage(svg: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const blob = new Blob([svg], { type: 'image/svg+xml;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const image = new Image();
    image.decoding = 'async';
    image.onload = () => {
      URL.revokeObjectURL(url);
      resolve(image);
    };
    image.onerror = (event) => {
      URL.revokeObjectURL(url);
      reject(event);
    };
    image.src = url;
  });
}

async function renderElementToCanvas(element: HTMLElement, scale: number): Promise<HTMLCanvasElement> {
  const rect = element.getBoundingClientRect();
  const width = Math.max(1, Math.ceil(rect.width));
  const height = Math.max(1, Math.ceil(rect.height));
  const clone = cloneWithInlineStyles(element, width, height);
  await inlineExternalImages(clone);
  await inlineBackgroundImages(clone);
  const serialized = new XMLSerializer().serializeToString(clone);
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}"><foreignObject width="100%" height="100%">${serialized}</foreignObject></svg>`;
  const image = await loadSvgImage(svg);
  const canvas = document.createElement('canvas');
  const effectiveScale = Number.isFinite(scale) && scale > 0 ? scale : 2;
  canvas.width = Math.max(1, Math.round(width * effectiveScale));
  canvas.height = Math.max(1, Math.round(height * effectiveScale));
  const context = canvas.getContext('2d');
  if (!context) {
    throw new Error('Unable to obtain canvas context for PDF export.');
  }
  context.scale(effectiveScale, effectiveScale);
  context.fillStyle = '#ffffff';
  context.fillRect(0, 0, width, height);
  context.drawImage(image, 0, 0, width, height);
  return canvas;
}

function decodeDataUrl(dataUrl: string): Uint8Array {
  const parts = dataUrl.split(',');
  if (parts.length < 2) {
    throw new Error('Invalid data URL for PDF export.');
  }
  const binary = atob(parts[1]);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }
  return bytes;
}

function createImageObject(objectNumber: number, image: PdfImageResource): string {
  const stream = Array.from(image.data)
    .map((byte) => String.fromCharCode(byte))
    .join('');
  return `${objectNumber} 0 obj << /Type /XObject /Subtype /Image /Width ${image.width} /Height ${image.height} /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ${image.data.length} >>\nstream\n${stream}\nendstream\nendobj`;
}

function buildPdfStream(objects: string[]): Uint8Array {
  const encoder = new TextEncoder();
  const header = '%PDF-1.4\n';
  const chunks: Uint8Array[] = [encoder.encode(header)];
  const offsets: string[] = ['0000000000 65535 f \n'];
  let position = header.length;

  objects.forEach((object) => {
    const chunk = encoder.encode(`${object}\n`);
    offsets.push(`${String(position).padStart(10, '0')} 00000 n \n`);
    chunks.push(chunk);
    position += chunk.length;
  });

  const startxref = position;
  const xref = `xref\n0 ${objects.length + 1}\n${offsets.join('')}trailer << /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${startxref}\n%%EOF`;
  chunks.push(encoder.encode(xref));

  const totalLength = chunks.reduce((sum, chunk) => sum + chunk.length, 0);
  const pdfBytes = new Uint8Array(totalLength);
  let offset = 0;
  chunks.forEach((chunk) => {
    pdfBytes.set(chunk, offset);
    offset += chunk.length;
  });

  return pdfBytes;
}

export async function generateInvoicePdf({ element, scale = 2, margin = 32 }: GenerateInvoicePdfOptions): Promise<Blob> {
  if (!element) {
    throw new Error('A preview element is required to export the invoice PDF.');
  }

  if ('fonts' in document && typeof document.fonts?.ready === 'object') {
    try {
      await document.fonts.ready;
    } catch (error) {
      console.warn('Unable to confirm font readiness before export.', error);
    }
  }

  const canvas = await renderElementToCanvas(element, scale);
  const dataUrl = canvas.toDataURL('image/jpeg', 0.95);
  const imageData = decodeDataUrl(dataUrl);

  const rect = element.getBoundingClientRect();
  const cssWidth = Math.max(1, Math.ceil(rect.width));
  const cssHeight = Math.max(1, Math.ceil(rect.height));
  const marginPx = Math.max(0, margin);

  const pageWidthPt = pxToPt(cssWidth + marginPx * 2);
  const pageHeightPt = pxToPt(cssHeight + marginPx * 2);
  const drawWidthPt = pxToPt(cssWidth);
  const drawHeightPt = pxToPt(cssHeight);
  const marginPt = pxToPt(marginPx);

  const objects: string[] = [];
  objects.push('1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj');
  objects.push(`2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 /MediaBox [0 0 ${pageWidthPt.toFixed(2)} ${pageHeightPt.toFixed(2)}] >> endobj`);

  const content = [
    'q',
    `${drawWidthPt.toFixed(2)} 0 0 ${drawHeightPt.toFixed(2)} ${marginPt.toFixed(2)} ${marginPt.toFixed(2)} cm`,
    '/ImPreview Do',
    'Q',
  ].join('\n');
  const contentBytes = new TextEncoder().encode(content);

  objects.push(
    `3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 ${pageWidthPt.toFixed(2)} ${pageHeightPt.toFixed(2)}] /Contents 4 0 R /Resources << /XObject << /ImPreview 5 0 R >> >> >> endobj`,
  );
  objects.push(`4 0 obj << /Length ${contentBytes.length} >> stream\n${content}\nendstream\nendobj`);
  objects.push(
    createImageObject(5, {
      name: 'ImPreview',
      data: imageData,
      width: canvas.width,
      height: canvas.height,
    }),
  );

  const pdfBytes = buildPdfStream(objects);
  return new Blob([pdfBytes], { type: 'application/pdf' });
}
