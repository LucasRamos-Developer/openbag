package com.openbag.platform.web;

import jakarta.servlet.ReadListener;
import jakarta.servlet.ServletInputStream;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;

/**
 * Requisição com o corpo já lido por um filtro (para o hash da idempotência ou o email do login), que o controller
 * lê de novo normalmente
 */
public final class CachedBodyRequest extends HttpServletRequestWrapper {

    private final byte[] body;

    private CachedBodyRequest(HttpServletRequest request, byte[] body) {
        super(request);
        this.body = body;
    }

    /** Lê o corpo uma vez; se a requisição já for um {@link CachedBodyRequest}, reaproveita */
    public static CachedBodyRequest of(HttpServletRequest request) throws IOException {
        if (request instanceof CachedBodyRequest cached) {
            return cached;
        }
        return new CachedBodyRequest(request, request.getInputStream().readAllBytes());
    }

    public byte[] getBody() {
        return body;
    }

    @Override
    public ServletInputStream getInputStream() {
        ByteArrayInputStream input = new ByteArrayInputStream(body);
        return new ServletInputStream() {
            @Override
            public int read() {
                return input.read();
            }

            @Override
            public int read(byte[] b, int off, int len) {
                return input.read(b, off, len);
            }

            @Override
            public boolean isFinished() {
                return input.available() == 0;
            }

            @Override
            public boolean isReady() {
                return true;
            }

            @Override
            public void setReadListener(ReadListener listener) {
                throw new UnsupportedOperationException();
            }
        };
    }

    @Override
    public BufferedReader getReader() {
        String encoding = getCharacterEncoding() != null ? getCharacterEncoding() : StandardCharsets.UTF_8.name();
        return new BufferedReader(new InputStreamReader(getInputStream(), Charset.forName(encoding)));
    }

    @Override
    public int getContentLength() {
        return body.length;
    }

    @Override
    public long getContentLengthLong() {
        return body.length;
    }
}
