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

        public List<Question> Shuffle()
        {

            Random random = new Random();

            _questions = _questions.OrderBy<Question, int>(item => random.Next()).ToList();

            foreach(var question in _questions)
            {
                question.ShuffleAnswers();
            }

            return _questions;
        }

        public override string ToString()
        {
            StringBuilder sb = new StringBuilder();

            for(int qi = 0; qi < _questions.Count; qi++)
            {
                sb.AppendLine($"{qi + 1}. {_questions[qi]}");
            }

            return sb.ToString();
        }

        public string ToStringLatex()
        {
            StringBuilder sb = new StringBuilder();

            sb.AppendLine("\\begin{enumerate}[1.]");
            for (int qi = 0; qi < _questions.Count; qi++)
            {
                sb.AppendLine($"\t\\item {_questions[qi].ToStringLatex()}");
            }
            sb.AppendLine("\\end{enumerate}");

            return sb.ToString();
        }
    }
}
