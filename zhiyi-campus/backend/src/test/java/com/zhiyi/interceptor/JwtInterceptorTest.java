package com.zhiyi.interceptor;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
class JwtInterceptorTest {

    private final JwtInterceptor interceptor = new JwtInterceptor(null, null);

    @Test
    void exactDynamicGetRoutesArePublic() throws Exception {
        MockHttpServletResponse itemResponse = new MockHttpServletResponse();
        MockHttpServletResponse cardResponse = new MockHttpServletResponse();

        assertTrue(interceptor.preHandle(
                new MockHttpServletRequest("GET", "/api/item/42"), itemResponse, new Object()));
        assertTrue(interceptor.preHandle(
                new MockHttpServletRequest("GET", "/api/user/42/card"), cardResponse, new Object()));
    }

    @Test
    void nonGetItemRoutesStillRequireAuthentication() throws Exception {
        MockHttpServletResponse putResponse = new MockHttpServletResponse();
        MockHttpServletResponse deleteResponse = new MockHttpServletResponse();

        assertFalse(interceptor.preHandle(
                new MockHttpServletRequest("PUT", "/api/item/42"), putResponse, new Object()));
        assertEquals(401, putResponse.getStatus());
        assertFalse(interceptor.preHandle(
                new MockHttpServletRequest("DELETE", "/api/item/42"), deleteResponse, new Object()));
        assertEquals(401, deleteResponse.getStatus());
    }

    @Test
    void itemSubRoutesAreNotTreatedAsPublicDetails() throws Exception {
        MockHttpServletResponse response = new MockHttpServletResponse();

        assertFalse(interceptor.preHandle(
                new MockHttpServletRequest("GET", "/api/item/42/favorite"), response, new Object()));
        assertEquals(401, response.getStatus());
    }
}
