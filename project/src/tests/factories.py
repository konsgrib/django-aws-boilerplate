"""
Sample test factories using factory_boy
"""
import factory
from django.contrib.auth import get_user_model
from faker import Faker

User = get_user_model()
fake = Faker()


class UserFactory(factory.django.DjangoModelFactory):
    """Factory for creating test users"""
    
    class Meta:
        model = User
    
    username = factory.LazyAttribute(lambda _: fake.user_name())
    email = factory.LazyAttribute(lambda _: fake.email())
    first_name = factory.LazyAttribute(lambda _: fake.first_name())
    last_name = factory.LazyAttribute(lambda _: fake.last_name())
    is_active = True
    is_staff = False
    is_superuser = False

    @factory.post_generation
    def password(self, create, extracted, **kwargs):
        if not create:
            return
        if extracted:
            self.set_password(extracted)
        else:
            self.set_password('defaultpassword123')


class AdminUserFactory(UserFactory):
    """Factory for creating admin users"""
    
    is_staff = True
    is_superuser = True
