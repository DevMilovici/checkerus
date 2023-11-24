using Models;
using quizapp;

ExcelFileService excelFileService = new ExcelFileService();

List<Question> questions = excelFileService.ReadQuestionsFromCsv("questions.csv");

Quiz quiz = new Quiz(questions);

for(int i = 0; i < questions.Count; i++)
{
    Console.WriteLine($"{i + 1}. {questions[i]}\n");
}


for(int setIndex = 0; setIndex < 4; setIndex++)
{
    string outputPath = $"set_{setIndex}.txt";
    FileInfo fileInfo = new FileInfo(outputPath);
    if(fileInfo.Exists)
        fileInfo.Delete();

    List<Question> questionsList = quiz.GetQuestionsAtRandom();

    for (int questionIndex = 0; questionIndex < questionsList.Count; questionIndex++)
    {
        File.AppendAllText(outputPath, $"{questionIndex + 1}. {questionsList[questionIndex]}\n");
    }
}
