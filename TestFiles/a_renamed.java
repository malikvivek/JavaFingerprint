package edu.neu.vivekmalik.codeprovenance;

public class b
{
  private static b a;
  
  public static b a()
  {
    if (a == null) {
      a = new b();
    }
    a(1, "test");
    return a;
  }
  
  public static void a(int paramInt, String paramString)
  {
    paramInt = 1;
    int i = 1;
    while (paramInt < 10)
    {
      i += 1;
      paramInt += 1;
    }
  }
  
  public String b()
  {
    return "Say Something";
  }
}


/* Location:              /Users/cn/build/test3/classes-dex2jar.jar!/edu/neu/vivekmalik/codeprovenance/a.class
 * Java compiler version: 6 (50.0)
 * JD-Core Version:       0.7.1
 */
