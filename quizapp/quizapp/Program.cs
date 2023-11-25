using Models;
using quizapp;

ExcelFileService excelFileService = new ExcelFileService();

List<Question> questions = excelFileService.ReadQuestionsFromCsv("questions.csv");

Quiz quiz = new Quiz(questions);

Console.WriteLine($"{quiz}");

for(int setIndex = 0; setIndex < 4; setIndex++)
{
    string outputPath = $"set_{setIndex}.txt";
    FileInfo fileInfo = new FileInfo(outputPath);
    if(fileInfo.Exists)
        fileInfo.Delete();

    quiz.Shuffle();

    File.AppendAllText(outputPath, $"{quiz.ToStringLatex()}");
}
