using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Models
{
    public class Quiz
    {
        List<Question> _questions;

        #region C-TORS

        public Quiz()
        {
            _questions = new List<Question>();
        }

        public Quiz(List<Question> questions)
        {
            _questions = questions;
        }

        #endregion

        public void AddQuestion(Question question)
        {
            _questions.Add(question);
        }

        public void RemoveQuestion(int index)
        {
            if(index < 0 || index >= _questions.Count || _questions.Count < 1)
                return;

            _questions.RemoveAt(index);
        }

        public Question GetQuestion(int index)
        {
            if (index < 0 || index >= _questions.Count || _questions.Count < 1)
                return null;

            return _questions[index];
        }

        public List<Question> GetQuestions()
        {
            return _questions;
        }

        public List<Question> GetQuestionsAtRandom()
        {

            Random random = new Random();

            List<Question> questionsRandom = _questions.OrderBy<Question, int>(item => random.Next()).ToList();

            foreach(var question in questionsRandom)
            {
                question.ShuffleAnswers();
            }

            return questionsRandom;
        }
    }
}
