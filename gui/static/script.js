// Function to handle signup
document.getElementById('signupForm')?.addEventListener('submit', async function(e) {
    e.preventDefault();

    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;

   // Example using fetch or axios
fetch("/signup", {
    method: "POST",
    headers: {
        "Content-Type": "application/json"
    },
    body: JSON.stringify({ email: email, password: password })
})
.then(response => response.json())
.then(data => {
   
        console.log("Signup successful:", data.message);
    
})
.catch(error => console.log("Error:", error));

});

document.getElementById('loginForm')?.addEventListener('submit', async function(e) {
    e.preventDefault();

    const email = document.getElementById('loginEmail').value;
    const password = document.getElementById('loginPassword').value;

    const response = await fetch('http://localhost:3000/login', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password }),
    });

    const result = await response.json();
    const messageElement = document.getElementById('loginMessage');
    if (response.ok) {
        // Store the JWT token in localStorage
        //alert(result.token)
        localStorage.setItem('token', result.token);
        
        messageElement.innerText = 'Login successful!';
        window.location.href = 'protected.html'; // Redirect to protected page
    } else {
        messageElement.innerText = 'Login failed: ' + result.message;
    }
});


async function loadProtectedContent() {
    const token = localStorage.getItem('token');
    const messageElement = document.getElementById('protectedMessage');
    //alert(token)
    if (token == null) {
        messageElement.innerText = 'You are not authorized!';
        return window.location.href = 'login.html'; // Redirect to login if no token
    }

    const response = await fetch('http://localhost:3000/validate', {
        method: 'GET',
        headers: {
            'Authorization': `Bearer ${token}`, // Include the JWT in the Authorization header
        },
    });

    const result = await response.json();
    if (response.ok) {
        messageElement.innerText = 'Protected message: ' + result.message;
    } else {
        messageElement.innerText = 'Access denied: ' + result.message;
        localStorage.removeItem('token'); // Remove token if unauthorized
        window.location.href = 'login.html'; // Redirect to login
    }
}

// Call the loadProtectedContent function when the protected page loads
if (document.getElementById('protectedMessage')) {
    window.onload = loadProtectedContent;
}
