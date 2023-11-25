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

        public string ToStringLatex()
        {
            StringBuilder sb = new StringBuilder();
            sb.AppendLine($"{Text}");

            sb.AppendLine("\t\\begin{enumerate}[a)]");
            for (int ai = 0; ai < Answers.Count; ai++)
            {
                Answers[ai] = Answers[ai].Replace("_", "\\textunderscore ");
                Answers[ai] = Answers[ai].Replace("<=", "\\leq");
                Answers[ai] = Answers[ai].Replace(">=", "\\geq");

                if (Answers[ai].Contains('^'))
                    sb.AppendLine($"\t\t\\item ${Answers[ai]}$");
                else
                    sb.AppendLine($"\t\t\\item {Answers[ai]}");
            }
            sb.AppendLine("\t\\end{enumerate}");

            return sb.ToString();
        }
    }
}