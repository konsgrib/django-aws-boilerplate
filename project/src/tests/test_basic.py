"""
Sample unit tests for Django application
"""
import pytest
from django.contrib.auth import get_user_model
from django.urls import reverse

User = get_user_model()


@pytest.mark.unit
@pytest.mark.django_db
class TestUserModel:
    """Test User model"""

    def test_create_user(self):
        """Test creating a regular user"""
        user = User.objects.create_user(
            username='newuser',
            email='newuser@example.com',
            password='password123'
        )
        assert user.username == 'newuser'
        assert user.email == 'newuser@example.com'
        assert user.is_active
        assert not user.is_staff
        assert not user.is_superuser

    def test_create_superuser(self):
        """Test creating a superuser"""
        admin = User.objects.create_superuser(
            username='admin',
            email='admin@example.com',
            password='adminpass123'
        )
        assert admin.is_staff
        assert admin.is_superuser


@pytest.mark.unit
@pytest.mark.django_db
class TestHealthEndpoint:
    """Test health check endpoint"""

    def test_health_endpoint_returns_200(self, api_client):
        """Health endpoint should return 200 OK"""
        response = api_client.get('/health/')
        assert response.status_code == 200
        assert b'healthy' in response.content


@pytest.mark.integration
@pytest.mark.django_db
class TestAdminAccess:
    """Test admin panel access"""

    def test_admin_login_page_loads(self, api_client):
        """Admin login page should load"""
        response = api_client.get('/admin/login/')
        assert response.status_code == 200

    def test_admin_redirects_when_not_authenticated(self, api_client):
        """Admin panel should redirect to login when not authenticated"""
        response = api_client.get('/admin/')
        assert response.status_code == 302
        assert '/admin/login/' in response.url

    def test_admin_accessible_when_authenticated(self, admin_client):
        """Admin panel should be accessible for authenticated admin"""
        response = admin_client.get('/admin/')
        assert response.status_code == 200

    def test_regular_user_cannot_access_admin(self, authenticated_client):
        """Regular user should not access admin panel"""
        response = authenticated_client.get('/admin/')
        # Should redirect to login or show permission denied
        assert response.status_code in [302, 403]
