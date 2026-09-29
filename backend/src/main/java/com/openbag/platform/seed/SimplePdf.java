package com.openbag.platform.seed;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

/**
 * PDF mínimo de uma página com título e linhas de texto (Helvetica). Só para os documentos de demonstração:
 * acentos saem pela codificação WinAnsi, que cobre o português.
 */
final class SimplePdf {

    private SimplePdf() {
    }

    static byte[] of(String title, List<String> lines) {
        StringBuilder content = new StringBuilder("BT /F1 18 Tf 56 780 Td (").append(escape(title)).append(") Tj ET\n");
        int y = 740;
        for (String line : lines) {
            content.append("BT /F1 11 Tf 56 ").append(y).append(" Td (").append(escape(line)).append(") Tj ET\n");
            y -= 18;
        }
        byte[] stream = content.toString().getBytes(StandardCharsets.ISO_8859_1);

        List<byte[]> objects = new ArrayList<>();
        objects.add(ascii("<< /Type /Catalog /Pages 2 0 R >>"));
        objects.add(ascii("<< /Type /Pages /Kids [3 0 R] /Count 1 >>"));
        objects.add(ascii("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] "
                + "/Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>"));
        objects.add(ascii("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>"));
        ByteArrayOutputStream contents = new ByteArrayOutputStream();
        contents.writeBytes(ascii("<< /Length " + stream.length + " >>\nstream\n"));
        contents.writeBytes(stream);
        contents.writeBytes(ascii("endstream"));
        objects.add(contents.toByteArray());

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        out.writeBytes(ascii("%PDF-1.4\n"));
        List<Integer> offsets = new ArrayList<>();
        for (int i = 0; i < objects.size(); i++) {
            offsets.add(out.size());
            out.writeBytes(ascii((i + 1) + " 0 obj\n"));
            out.writeBytes(objects.get(i));
            out.writeBytes(ascii("\nendobj\n"));
        }
        int xref = out.size();
        StringBuilder table = new StringBuilder("xref\n0 ").append(objects.size() + 1).append("\n0000000000 65535 f \n");
        for (int offset : offsets) {
            table.append(String.format("%010d 00000 n \n", offset));
        }
        table.append("trailer\n<< /Size ").append(objects.size() + 1).append(" /Root 1 0 R >>\nstartxref\n")
                .append(xref).append("\n%%EOF\n");
        out.writeBytes(ascii(table.toString()));
        return out.toByteArray();
    }

    private static String escape(String text) {
        return text.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)");
    }

    private static byte[] ascii(String text) {
        return text.getBytes(StandardCharsets.ISO_8859_1);
    }
}
