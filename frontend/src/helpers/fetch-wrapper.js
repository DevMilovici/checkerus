import useAuthStore from "@/stores/auth";

const API_URL = `${import.meta.env.VITE_API_URL}`;

export default {
  get: request("GET"),
  post: request("POST"),
  put: request("PUT"),
  delete: request("DELETE"),
  upload: uploadFile("POST"),
};

function request(method) {
    return (url, body) => {
        const requestOptions = {
            method,
            headers: authHeader(url)
        };
        if(body) {
            requestOptions.headers["Content-Type"] = "application/json";
            requestOptions.body = JSON.stringify(body);
        }
        return fetch(url, requestOptions)
            .then(handleResponse)
            .catch((error) => {
                return { success: false, error: error };
            });
    }
}

function handleResponse(response) {
    return response.text().then((text) => {
      const data = text && JSON.parse(text);
  
      if (!response.ok) {
        const error = {
          ok: response.ok,
          statusText: response.statusText,
          status: response.status,
          success: data?.success ?? false,
          error_message: data.error_message,
        };
        return Promise.reject(error);
      }
  
      if(!data) {
        data = {};
      }
      data.success = true;
      return data;
    });
}

function authHeader(url) {
    // Return auth header with jwt if user is logged in and request is to the api url
    const authStore = useAuthStore();
    const isApiUrl = url.startsWith(API_URL);
    if (authStore?.isAuthenticated && isApiUrl) {
        return { Authorization: `Bearer ${authStore.user.auth_token}` };
    } else {
        return {};
    }
}

function uploadFile(method) {
    return (url, fileFormData) => {
      const requestOptions = {
        method: method,
        headers: authHeader(url),
        body: fileFormData,
      };
  
      return fetch(url, requestOptions)
        .then(handleResponse)
        .catch((error) => {
          return { success: false, error: error };
        }
      );
    };
  }