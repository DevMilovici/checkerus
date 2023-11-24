using Models;
using Microsoft.VisualBasic.FileIO;
using CsvHelper;
using CsvHelper.Configuration;
using System.Globalization;

namespace quizapp
{
    public class ExcelFileService
    {
        public ExcelFileService()
        {}

        public void Write(string path, List<Question> questions)
        {

        }

        //public List<Question> ReadQuestionsFromCsv(string filePath)
        //{
        //    List<Question> questions;

        //    CsvConfiguration csvConfiguration = new CsvConfiguration(CultureInfo.InvariantCulture);
        //    csvConfiguration.HasHeaderRecord = false;

        //    using (var reader = new StreamReader(filePath))
        //    using (var csv = new CsvReader(reader, csvConfiguration))
        //    {
        //        questions = csv.GetRecords<Question>().ToList();
        //    }

        //    return questions;
        //}

        public List<Question> ReadQuestionsFromCsv(string filePath)
        {
            List<Question> questions = new List<Question>();

            using (TextFieldParser parser = new TextFieldParser(filePath))
            {
                parser.TextFieldType = FieldType.Delimited;
                parser.SetDelimiters(",");

                while (!parser.EndOfData)
                {
                    string[] fields = parser.ReadFields();
                    if (fields != null && fields.Length > 1)
                    {
                        string questionText = fields[0];
                        List<string> answers = fields.Skip(1).ToList();

                        Question question = new Question(questionText, answers);
                        questions.Add(question);
                    }
                }
            }

            return questions;
        }
    }
}
