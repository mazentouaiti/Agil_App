from rest_framework import generics, status
from rest_framework.response import Response
from .serializers import UserSerializer
from django.http import JsonResponse
from rest_framework_simplejwt.views import TokenObtainPairView 
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from django.contrib.auth import get_user_model


User = get_user_model()

class SignUpView(generics.CreateAPIView):
    serializer_class = UserSerializer

    def create(self, request, *args, **kwargs):
        print("Incoming data:", request.data)
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            print("Validation errors:", serializer.errors)
            serializer.save()
            return Response(
                {'message': 'User created successfully'},
                status=status.HTTP_201_CREATED
            )
        return Response(
            {'message': 'Registration failed', 'errors': serializer.errors},
            status=status.HTTP_400_BAD_REQUEST
        )


def home(request):
    return JsonResponse({
        'message': 'Welcome to Agil Energy API',
        'endpoints': {
            'signup': '/api/signup/',
            'admin': '/admin/'
        }
    })


class CustomTokenObtainPairView(TokenObtainPairView):
    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        
        if not serializer.is_valid():
            return Response(
                {"message": "Invalid credentials"},
                status=status.HTTP_401_UNAUTHORIZED
            )
            
        return Response({
            "message": "Login successful",
            "access": serializer.validated_data.get("access"),
            "refresh": serializer.validated_data.get("refresh"),
        })
    

class LoginView(APIView):
    def post(self, request):
        email = request.data.get('email', '').lower().strip()
        password = request.data.get('password', '').strip()
        
        # Debug prints
        print(f"Attempting login for: {email}")
        
        # First try direct authentication
        user = authenticate(request, username=email, password=password)
        
        # Fallback: Check user directly if authenticate fails
        if user is None:
            try:
                user = User.objects.get(email=email)
                if user.check_password(password):
                    print("Password matches but authenticate failed")
                else:
                    print("Password mismatch")
                    return Response({"error": "Invalid credentials"}, status=400)
            except User.DoesNotExist:
                print("User not found")
                return Response({"error": "Invalid credentials"}, status=400)
        
        if user is not None:
            refresh = RefreshToken.for_user(user)
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'user_id': user.id,
                'email': user.email
            })
        
        return Response({"error": "Invalid credentials"}, status=400)