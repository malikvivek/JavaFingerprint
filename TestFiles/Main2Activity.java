package edu.neu.vivekmalik.codeprovenance;

import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;

public class Main2Activity
  extends AppCompatActivity
{
  protected void onCreate(Bundle paramBundle)
  {
    super.onCreate(paramBundle);
    setContentView(2130968604);
    ((Button)findViewById(2131558521)).setOnClickListener(new View.OnClickListener()
    {
      public void onClick(View paramAnonymousView)
      {
        paramAnonymousView = new Intent("android.intent.action.VIEW", Uri.parse("http://www.google.com"));
        paramAnonymousView.addCategory("android.intent.category.BROWSABLE");
        paramAnonymousView.setPackage("com.android.chrome");
        try
        {
          Main2Activity.this.startActivity(paramAnonymousView);
          return;
        }
        catch (ActivityNotFoundException localActivityNotFoundException)
        {
          paramAnonymousView.setPackage(null);
          Main2Activity.this.startActivity(paramAnonymousView);
        }
      }
    });
  }
}


/* Location:              /Users/cn/build/test3/classes-dex2jar.jar!/edu/neu/vivekmalik/codeprovenance/Main2Activity.class
 * Java compiler version: 6 (50.0)
 * JD-Core Version:       0.7.1
 */
