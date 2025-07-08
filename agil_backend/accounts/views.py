from rest_framework import generics, status
from rest_framework.response import Response
from .serializers import UserSerializer
from django.http import JsonResponse

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