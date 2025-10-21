from locust import HttpUser, task, between
import random

class SampleAppUser(HttpUser):
    wait_time = between(1, 5)
    
    def on_start(self):
        """Called when a Locust user starts running."""
        pass
    
    @task(3)
    def get_users(self):
        """Get list of users"""
        self.client.get("/api/users")
    
    @task(2)
    def get_user(self):
        """Get a specific user"""
        user_id = random.randint(1, 100)
        self.client.get(f"/api/users/{user_id}")
    
    @task(1)
    def create_user(self):
        """Create a new user"""
        payload = {
            "name": f"User{random.randint(1, 10000)}",
            "email": f"user{random.randint(1, 10000)}@example.com"
        }
        self.client.post("/api/users", json=payload)