/// Mock Onboarding Questions - Phase 2
/// 
/// Sample questions matching the API structure for testing without backend
/// Based on Figma Frames 2-7
const Map<String, dynamic> mockOnboardingResponse = {
  "questions": [
    // Frame 2: Gender Selection (Figma format: "Hey, Muskan. How do you identify as?")
    {
      "_id": "mock_q1",
      "text": "Hey, Muskan.\nHow do you identify as?",
      "type": "TEXT_MCQ",
      "question_set": "USER_ONBOARDING",
      "category": "lifestyle",
      "options": [
        {
          "id": "opt_male",
          "text": "Male",
          "vector_text": "Male"
        },
        {
          "id": "opt_female",
          "text": "Female",
          "vector_text": "Female"
        }
      ],
      "is_required": true,
      "order": 1,
      "help_text": null
    },
    
    // Frame 3: Age (TEXT_INPUT - Figma format: "Where do you see yourself happy at?")
    {
      "_id": "mock_q2",
      "text": "Where do you see yourself happy at?",
      "type": "TEXT_INPUT",
      "question_set": "USER_ONBOARDING",
      "category": "lifestyle",
      "options": [],
      "is_required": true,
      "order": 2,
      "help_text": "Type here..."
    },
    
    // Frame 4: Priorities (Multi-select chips - Figma format: "What do you do for a living, seksdays?")
    {
      "_id": "mock_q3",
      "text": "What do you do for a living, seksdays?",
      "type": "TEXT_MCQ",
      "question_set": "USER_ONBOARDING",
      "category": "preferences",
      "options": [
        {
          "id": "opt_code",
          "text": "I Code",
          "vector_text": "I am a software developer"
        },
        {
          "id": "opt_sell",
          "text": "I sell",
          "vector_text": "I work in sales"
        },
        {
          "id": "opt_business",
          "text": "Some business stuff",
          "vector_text": "I run a business"
        },
        {
          "id": "opt_nothing",
          "text": "Nothing",
          "vector_text": "I am currently unemployed"
        }
      ],
      "is_required": true,
      "order": 3,
      "help_text": null,
      "multi_select": false,
      "max_selections": null
    },
    
    // Frame 5: Weekend Activities (Icon grid - Figma format: "What is your favorite Saturday scene?")
    {
      "_id": "mock_q4",
      "text": "What is your favorite Saturday scene?",
      "type": "IMAGE_MCQ",
      "question_set": "USER_ONBOARDING",
      "category": "lifestyle",
      "options": [
        {
          "id": "opt_travel",
          "text": "Travel",
          "vector_text": "I enjoy traveling",
          "image_url": null // Will use icons instead
        },
        {
          "id": "opt_binge",
          "text": "Binge Watch",
          "vector_text": "I enjoy binge watching",
          "image_url": null
        },
        {
          "id": "opt_exercise",
          "text": "Exercise",
          "vector_text": "I enjoy exercising",
          "image_url": null
        },
        {
          "id": "opt_pet",
          "text": "Play with pet",
          "vector_text": "I play with pets",
          "image_url": null
        },
        {
          "id": "opt_ideas",
          "text": "Work on my ideas",
          "vector_text": "I work on side projects",
          "image_url": null
        },
        {
          "id": "opt_sports",
          "text": "Sports",
          "vector_text": "I enjoy sports",
          "image_url": null
        },
        {
          "id": "opt_dates",
          "text": "Go on dates",
          "vector_text": "I go on dates",
          "image_url": null
        },
        {
          "id": "opt_other",
          "text": "Something else",
          "vector_text": "I do other activities",
          "image_url": null
        }
      ],
      "is_required": true,
      "order": 4,
      "help_text": "Select all that apply",
      "multi_select": true
    },
    
    // Frame 6 & 7: Combined as one question with multiple selections
    {
      "_id": "mock_q5",
      "text": "Hushh.. Last 2 questions.\nAre you?",
      "type": "TEXT_MCQ",
      "question_set": "USER_ONBOARDING",
      "category": "lifestyle",
      "options": [
        {
          "id": "opt_veg",
          "text": "Veg",
          "vector_text": "I am vegetarian"
        },
        {
          "id": "opt_non_veg",
          "text": "Non-veg",
          "vector_text": "I am non-vegetarian"
        },
        {
          "id": "opt_smoker",
          "text": "Smoker",
          "vector_text": "I am a smoker"
        },
        {
          "id": "opt_non_smoker",
          "text": "Non-Smoker",
          "vector_text": "I am a non-smoker"
        }
      ],
      "is_required": true,
      "order": 5,
      "help_text": null,
      "multi_select": true,
      "max_selections": 2
    }
  ],
  "total_questions": 5,
  "categories": ["lifestyle", "preferences"],
  "user_role": "SEEKER"
};

