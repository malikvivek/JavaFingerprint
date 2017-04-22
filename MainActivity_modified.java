package edu.neu.vivekmalik.codeprovenance;

import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;
import java.util.List;
import java.util.Locale;

public class MainActivity
  extends AppCompatActivity
{
  TextView a;
  TextView b;
  private final LocationListener c = new LocationListener()
  {
    public void onLocationChanged(Location paramAnonymousLocation)
    {
      MainActivity.this.b.setText("Lat:" + paramAnonymousLocation.getLatitude() + " Lon:" + paramAnonymousLocation.getLongitude());
      Log.e("MainActivity", "onLocationChanged");
    }
    
    public void onProviderDisabled(String paramAnonymousString)
    {
      Log.e("MainActivity", "onProviderDisabled");
    }
    
    public void onProviderEnabled(String paramAnonymousString)
    {
      Log.e("MainActivity", "onProviderEnabled");
    }
    
    public void onStatusChanged(String paramAnonymousString, int paramAnonymousInt, Bundle paramAnonymousBundle)
    {
      Log.e("MainActivity", "onStatusChanged");
    }
  };
  
  protected void onActivityResult(int paramInt1, int paramInt2, Intent paramIntent)
  {
    if ((paramInt1 == 1235) && (paramInt2 == -1))
    {
      paramIntent = paramIntent.getStringArrayListExtra("android.speech.extra.RESULTS");
      if (paramIntent.size() > 0) {
        this.a.setText((CharSequence)paramIntent.get(0));
      }
    }
    else
    {
      return;
    }
    this.a.setText("Please visit http://malware.url.com/");
  }
  
  protected void onCreate(Bundle paramBundle)
  {
    super.onCreate(paramBundle);
    setContentView(2130968603);
    this.a = ((TextView)findViewById(2131558518));
    this.b = ((TextView)findViewById(2131558519));
    ((Button)findViewById(2131558516)).setOnClickListener(new View.OnClickListener()
    {
      public void onClick(View paramAnonymousView)
      {
        paramAnonymousView = new Intent(MainActivity.this, Main2Activity.class);
        MainActivity.this.startActivity(paramAnonymousView);
      }
    });
    ((Button)findViewById(2131558517)).setOnClickListener(new View.OnClickListener()
    {
      public void onClick(View paramAnonymousView)
      {
        paramAnonymousView = new Intent("android.speech.action.RECOGNIZE_SPEECH");
        paramAnonymousView.putExtra("android.speech.extra.LANGUAGE_MODEL", "free_form");
        paramAnonymousView.putExtra("android.speech.extra.LANGUAGE", Locale.getDefault());
        paramAnonymousView.putExtra("android.speech.extra.PROMPT", a.a().b());
        try
        {
          MainActivity.this.startActivityForResult(paramAnonymousView, 1235);
          return;
        }
        catch (ActivityNotFoundException paramAnonymousView)
        {
          Toast.makeText(MainActivity.this.getApplicationContext(), "Speech not supported", 0).show();
        }
      }
    });
    try
    {
      ((LocationManager)getSystemService("location")).requestLocationUpdates("gps", 1000L, 100.0F, this.c);
      return;
    }
    catch (SecurityException paramBundle)
    {
      Log.e("MainActivity", "Exception Occured while checking for permissions");
      this.b.setText("Exception while fetching location");
    }
  }
}


/* Location:              /Users/cn/build/test3/classes-dex2jar.jar!/edu/neu/vivekmalik/codeprovenance/MainActivity.class
 * Java compiler version: 6 (50.0)
 * JD-Core Version:       0.7.1
 */
