import google.generativeai as genai
from config import settings
import logging
import json
from google.generativeai.types import HarmCategory, HarmBlockThreshold

logger = logging.getLogger(__name__)

class GeminiService:
    def __init__(self, api_key=settings.GEMINI_API_KEY):
        """Initializes the Gemini Service."""
        if not api_key:
            raise ValueError("Gemini API Key is required.")
        try:
            genai.configure(api_key=api_key)
        except Exception as e:
            logger.error(f"Failed to configure Gemini API key: {e}")
            raise ValueError(f"Failed to configure Gemini API key: {e}")

        self.safety_settings = {
            HarmCategory.HARM_CATEGORY_HARASSMENT: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
            HarmCategory.HARM_CATEGORY_HATE_SPEECH: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
            HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
            HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
        }
        logger.info("Gemini Service Initialized")

    def get_model(self, model_name=settings.GEMINI_FAST_MODEL, tools=None):
        """Initializes and returns a generative model instance."""
        resolved_model_name = model_name if model_name else settings.GEMINI_FAST_MODEL
        try:
            model_params = {
                "model_name": resolved_model_name,
                "safety_settings": self.safety_settings,
                "generation_config": {
                    "temperature": 0.7,
                }
            }
            if tools:
                if not isinstance(tools, list) or not all(isinstance(t, genai.types.FunctionDeclaration) for t in tools):
                    logger.warning(f"Invalid 'tools' format provided to get_model.")
                else:
                    model_params["tools"] = tools

            logger.debug(f"Initializing model: {resolved_model_name} with params: {model_params}")
            return genai.GenerativeModel(**model_params)
        except Exception as e:
            logger.error(f"Error initializing Gemini model {resolved_model_name}: {e}", exc_info=True)
            raise

    def generate_text(self, prompt: str, model_name=None) -> str:
        """Generates text content based on a prompt."""
        model_to_use = model_name if model_name else settings.GEMINI_FAST_MODEL
        try:
            model = self.get_model(model_to_use)
            logger.info(f"Generating text with model: {model_to_use}")
            response = model.generate_content(prompt)
            logger.debug(f"Raw text generation response: {response}")

            if not response.candidates:
                logger.warning(f"Gemini response blocked for prompt: {prompt[:100]}...")
                feedback_msg = ""
                try:
                    feedback = response.prompt_feedback
                    feedback_msg = f" (Feedback: {feedback})"
                    logger.warning(f"Safety feedback: {feedback}")
                except Exception:
                    pass
                return f"My response was blocked due to safety settings{feedback_msg}. Could you please rephrase?"

            if hasattr(response, 'text') and response.text:
                logger.info(f"Gemini text generation successful for model {model_to_use}.")
                return response.text
            else:
                logger.warning(f"Gemini returned no text for prompt: {prompt[:100]}... Candidates: {response.candidates}")
                try:
                    if response.candidates[0].content and response.candidates[0].content.parts:
                        fallback_text = "".join(part.text for part in response.candidates[0].content.parts if hasattr(part, 'text'))
                        if fallback_text:
                            logger.warning("Using joined text from parts as fallback.")
                            return fallback_text
                except Exception:
                    pass
                return "Sorry, I received an empty response. Could you try again?"

        except Exception as e:
            logger.error(f"Error during Gemini text generation with {model_to_use}: {e}", exc_info=True)
            return "Sorry, I encountered an error trying to generate a response."

    def generate_with_tools(self, prompt: str, tools: list, tool_functions: dict, model_name=None) -> str:
        """Generates content using function calling/tools, passing dict for response."""
        model_to_use = model_name if model_name else settings.GEMINI_FAST_MODEL

        try:
            logger.info(f"Generating with tools using model: {model_to_use}")
            model = self.get_model(model_to_use, tools=tools)
            chat = model.start_chat()
            response = chat.send_message(prompt)
            logger.debug(f"Initial response from model (Tools): {response}")

            while True:
                try:
                    candidate = response.candidates[0]
                    if not (candidate.content and candidate.content.parts and
                            hasattr(candidate.content.parts[0], 'function_call') and
                            candidate.content.parts[0].function_call.name):
                        break 
                    function_call = candidate.content.parts[0].function_call
                except (IndexError, AttributeError, TypeError) as e:
                    logger.warning(f"Could not access function call in response, assuming no call. Error: {e}. Response: {response}")
                    break

                tool_name = function_call.name
                args = function_call.args

                if tool_name not in tool_functions:
                    logger.error(f"Model requested unknown tool: {tool_name}")
                    return f"Error: The model tried to use an unknown tool ('{tool_name}')."

                logger.info(f"Executing tool: {tool_name} with raw args: {args}")
                function_to_call = tool_functions[tool_name]

                try:
                    args_dict = dict(args)
                    logger.debug(f"Converted args to dict: {args_dict}")
                    function_response_content = function_to_call(**args_dict)
                    logger.debug(f"Tool function '{tool_name}' executed successfully.")
                except Exception as e:
                    logger.error(f"Error executing tool function {tool_name}: {e}", exc_info=True)
                    function_response_content = json.dumps({"error": f"Error executing tool {tool_name}: {str(e)}"})

                logger.debug(f"Tool function response content (first 200 chars): {str(function_response_content)[:200]}...")

                try:
                    logger.info(f"Sending response from tool '{tool_name}' back to model as dictionary.")
                    tool_response_dict = {
                        "function_response": {
                            "name": tool_name,
                            "response": {
                                "content": function_response_content,
                            }
                        }
                    }
                    response = chat.send_message(tool_response_dict)
                    logger.debug(f"Response after sending tool result dict back to model: {response}")
                except Exception as e:
                    logger.error(f"Error sending tool response dict back to model: {e}", exc_info=True)
                    return "Sorry, an error occurred while communicating the tool result back to the AI."

            # Process the final response from the model
            if not response.candidates:
                logger.warning(f"Gemini final response blocked (after tools) for prompt: {prompt[:100]}...")
                feedback_msg = ""
                try:
                    feedback = response.prompt_feedback
                    feedback_msg = f" (Feedback: {feedback})"
                    logger.warning(f"Safety feedback: {feedback}")
                except Exception:
                    pass
                return f"My final response was blocked due to safety settings{feedback_msg}. Could you please rephrase?"

            if hasattr(response, 'text') and response.text:
                logger.info("Final response text received.")
                return response.text
            else:
                logger.warning(f"Gemini returned no final text after tool use for prompt: {prompt[:100]}... Candidates: {response.candidates}")
                try:
                    final_content = response.candidates[0].content
                    logger.warning(f"Final Candidate Content: {final_content}")
                    if final_content and final_content.parts:
                        fallback_text = "".join(part.text for part in final_content.parts if hasattr(part, 'text'))
                        if fallback_text:
                            logger.warning("Using joined text from final parts as fallback.")
                            return fallback_text
                except Exception as e:
                    logger.error(f"Error accessing final candidate content details: {e}")
                return "Sorry, I wasn't able to formulate a final text response after using the required tools. Please try again."

        except Exception as e:
            logger.error(f"Error during Gemini generation with tools using {model_to_use}: {e}", exc_info=True)
            return "Sorry, I encountered an unexpected error while processing your request with tools."

    def classify_intent(self, user_input: str, possible_intents: list, model_name=None) -> str:
        """
        Classifies user input into one of the possible intents using Gemini.
        Args: user_input, possible_intents list, optional model_name.
        Returns: Classified intent string or "Unclear/General".
        """
        model_to_use = model_name if model_name else settings.GEMINI_FAST_MODEL
        logger.debug(f"Using model '{model_to_use}' for intent classification.")

        intent_list_str = "\n".join([f"- {intent}" for intent in possible_intents])
        prompt = f"""
        Analyze the user's input and classify it into ONE of the following categories:
        {intent_list_str}
        - Unclear/General

        User Input: "{user_input}"

        Respond with ONLY the category name (e.g., "Q&A", "News Request", "Profile Update", "Portfolio Request", "Unclear/General").
        """
        try:
            model = self.get_model(model_to_use)
            logger.info(f"Classifying intent with model: {model_to_use}")
            response = model.generate_content(prompt)
            logger.debug(f"Raw intent classification response: {response}")

            if not response.candidates:
                logger.warning(f"Intent classification response blocked for input: {user_input[:100]}...")
                feedback_msg = ""
                try:
                    feedback = response.prompt_feedback
                    feedback_msg = f" (Feedback: {feedback})"
                    logger.warning(f"Safety feedback: {feedback}")
                except Exception:
                    pass
                return "Unclear/General"

            if not hasattr(response, 'text') or not response.text:
                logger.warning(f"Intent classification returned no text for input: {user_input[:100]}... Candidates: {response.candidates}")
                return "Unclear/General"

            intent = response.text.strip()
            logger.info(f"Intent classification raw response text: '{intent}' for input: '{user_input[:50]}...'")

            valid_intents = possible_intents + ["Unclear/General"]
            if intent in valid_intents:
                logger.info(f"Intent classified (exact match): '{intent}'")
                return intent
            else:
                for valid_intent in valid_intents:
                    if valid_intent.lower() in intent.lower():
                        logger.warning(f"Gemini returned '{intent}', mapping leniently to '{valid_intent}'.")
                        return valid_intent

                logger.warning(f"Gemini returned unexpected intent '{intent}'. Defaulting to Unclear/General.")
                return "Unclear/General"

        except Exception as e:
            logger.error(f"Error during Gemini intent classification with {model_to_use}: {e}", exc_info=True)
            return "Unclear/General"

# Instantiate the service
gemini_service = GeminiService()