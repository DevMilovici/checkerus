using System.Text;

namespace Models
{
    public class Question
    {
        public Question(string text, List<string> answers)
        {
            Text = text;
            Answers = answers;
        }

        public string Text { get; set; }
        List<string> Answers { get; set; }

        public void ShuffleAnswers()
        {
            Random random = new Random();
            Answers = Answers.OrderBy<string, int>(item => random.Next()).ToList();
        }

        public override string ToString()
        {
            StringBuilder stringBuilder = new StringBuilder();
            stringBuilder.AppendLine($"{Text}");

            for(int i = 0; i < Answers.Count; i++)
            {
                char answerLetter = (char)('a' + i);
                stringBuilder.AppendLine($"\t{answerLetter}) {Answers[i]}");
            }
            
            return stringBuilder.ToString();
        }
    }
}