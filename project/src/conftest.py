"""
Pytest configuration and shared fixtures
"""
import pytest
from django.contrib.auth import get_user_model
from django.test import Client

User = get_user_model()


@pytest.fixture
def api_client():
    """Django test client"""
    return Client()


@pytest.fixture
def user(db):
    """Create a regular user"""
    return User.objects.create_user(
        username='testuser',
        email='testuser@example.com',
        password='testpass123'
    )


@pytest.fixture
def admin_user(db):
    """Create an admin/superuser"""
    return User.objects.create_superuser(
        username='admin',
        email='admin@example.com',
        password='adminpass123'
    )


@pytest.fixture
def authenticated_client(api_client, user):
    """Client authenticated as regular user"""
    api_client.force_login(user)
    return api_client


@pytest.fixture
def admin_client(api_client, admin_user):
    """Client authenticated as admin"""
    api_client.force_login(admin_user)
    return api_client
