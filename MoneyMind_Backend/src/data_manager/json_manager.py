import json
import os
from config import settings
import logging

logger = logging.getLogger(__name__)

class JsonManager:
    def __init__(self, data_dir=settings.DATA_DIR):
        self.data_dir = data_dir
        if not os.path.exists(self.data_dir):
            os.makedirs(self.data_dir)
            logger.info(f"Created data directory: {self.data_dir}")

    def _get_user_filepath(self, user_id: str) -> str:
        """Constructs the file path for a given user ID."""
        safe_user_id = "".join(c for c in user_id if c.isalnum() or c in ('_', '-'))
        return os.path.join(self.data_dir, f"user_{safe_user_id}_data.json")

    def load_user_data(self, user_id: str) -> dict:
        """Loads user data from a JSON file. Creates default if not found."""
        filepath = self._get_user_filepath(user_id)
        try:
            with open(filepath, 'r') as f:
                data = json.load(f)
                logger.info(f"Loaded data for user: {user_id}")
                return data
        except FileNotFoundError:
            logger.info(f"No data file found for user: {user_id}. Creating default structure.")
            default_data = settings.DEFAULT_USER_STRUCTURE.copy()
            default_data['user_id'] = user_id 
            self.save_user_data(user_id, default_data)
            return default_data
        except json.JSONDecodeError:
            logger.error(f"Error decoding JSON for user: {user_id}. Returning default structure.")
            default_data = settings.DEFAULT_USER_STRUCTURE.copy()
            default_data['user_id'] = user_id
            return default_data 

    def save_user_data(self, user_id: str, data: dict) -> bool:
        """Saves user data to a JSON file."""
        filepath = self._get_user_filepath(user_id)
        try:
            if data.get('user_id') != user_id:
                logger.warning(f"Mismatch between user_id in data ('{data.get('user_id')}') and requested save ID ('{user_id}'). Updating data.")
                data['user_id'] = user_id

            with open(filepath, 'w') as f:
                json.dump(data, f, indent=2)
            logger.info(f"Successfully saved data for user: {user_id}")
            return True
        except IOError as e:
            logger.error(f"Error saving data for user {user_id}: {e}")
            return False
        except Exception as e:
            logger.error(f"An unexpected error occurred while saving data for {user_id}: {e}")
            return False
        
json_manager = JsonManager()