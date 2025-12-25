#!/bin/bash

# Firestore Rules Deployment Script
# This script helps you deploy your Firestore security rules

echo "🔒 Firestore Rules Deployment"
echo "=============================="
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null
then
    echo "❌ Firebase CLI is not installed."
    echo ""
    echo "To install Firebase CLI, run:"
    echo "  npm install -g firebase-tools"
    echo ""
    exit 1
fi

echo "✅ Firebase CLI is installed"
echo ""

# Check if user is logged in
if ! firebase projects:list &> /dev/null
then
    echo "❌ You are not logged in to Firebase."
    echo ""
    echo "Please run: firebase login"
    echo ""
    exit 1
fi

echo "✅ You are logged in to Firebase"
echo ""

# Check if firestore.rules exists
if [ ! -f "firestore.rules" ]; then
    echo "❌ firestore.rules file not found!"
    echo ""
    echo "Please make sure firestore.rules exists in the project root."
    exit 1
fi

echo "✅ firestore.rules file found"
echo ""

# Show current project
echo "Current Firebase project:"
firebase use

echo ""
echo "📋 Preview of your rules:"
echo "------------------------"
head -n 20 firestore.rules
echo "... (showing first 20 lines)"
echo ""

# Ask for confirmation
read -p "Do you want to deploy these rules? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo ""
    echo "🚀 Deploying Firestore rules..."
    firebase deploy --only firestore:rules
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Rules deployed successfully!"
        echo ""
        echo "You can view your rules at:"
        echo "https://console.firebase.google.com/project/$(firebase use | grep -o '\[.*\]' | tr -d '[]')/firestore/rules"
    else
        echo ""
        echo "❌ Deployment failed. Please check the error above."
        exit 1
    fi
else
    echo ""
    echo "❌ Deployment cancelled."
    exit 0
fi
