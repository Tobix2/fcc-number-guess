#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
SECRET_NUMBER=$(( $RANDOM % 1000 + 1 ))
# echo "$SECRET_NUMBER"

ASK_USERNAME(){
  echo -e "\nEnter your username:"
  read USERNAME

  USERNAME_CHARACTERS=$(echo $USERNAME | wc -c)
  if [[ $USERNAME_CHARACTERS -gt 22 ]]
  then
    ASK_USERNAME
  fi
}

ASK_USERNAME
RETURNING_USER=$($PSQL "SELECT username FROM users WHERE username = '$USERNAME'")
# RETURNING_USER_HAS_ONE=$($PSQL "SELECT COUNT(*) FROM users INNER JOIN games USING(user_id) WHERE username = '$USERNAME'")
if [[ -z $RETURNING_USER ]]
then
  INSERTED_USER=$($PSQL "INSERT INTO users (username) VALUES ('$USERNAME')")
  echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."

else
  GAMES_PLAYED=$($PSQL "SELECT COUNT(*) FROM games INNER JOIN users USING(user_id) WHERE username = '$USERNAME'")
  BEST_GAME=$($PSQL "SELECT MIN(guesses) FROM games INNER JOIN users USING(user_id) WHERE username = '$USERNAME'")
  GAMES=$(if [[ $GAMES_PLAYED -eq 1 ]]; then echo "game"; else echo "games"; fi)
  GUESSES=$(if [[ $BEST_GAME -eq 1 ]]; then echo "guess"; else echo "guesses"; fi)
  echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Grab user_id
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'")

TRIES=1
GUESS=0

GUESSING_MACHINE(){

  read GUESS


  while [[ $GUESS =~ ^[+-]?[0-9]+$ && ! $GUESS -eq $SECRET_NUMBER ]]
  do

    TRIES=$(expr $TRIES + 1)

    if [[ $GUESS -gt $SECRET_NUMBER ]]
    then

      echo -e "\nIt's lower than that, guess again:"
      read GUESS

    elif [[ $GUESS -lt $SECRET_NUMBER ]]
    then

      echo -e "\nIt's higher than that, guess again:"
      read GUESS

    fi
  done

  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
      echo -e "\nThat is not an integer, guess again:"
      TRIES=$(expr $TRIES + 1)
      GUESSING_MACHINE
  fi

}

echo -e "\nGuess the secret number between 1 and 1000:"
GUESSING_MACHINE

# insert data from game
INSERTED_GAME=$($PSQL "INSERT INTO games (user_id, guesses) VALUES ($USER_ID, $TRIES)")
PLURAL_TRIES=$(if [[ $TRIES -eq 1 ]]; then echo "try"; else echo "tries"; fi)
echo  -e "\nYou guessed it in $TRIES tries. The secret number was $SECRET_NUMBER. Nice job!"
