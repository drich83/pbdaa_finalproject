import java.io.IOException;

import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

public class NYPD_CleanReducer
    extends Reducer<Text, IntWritable, Text, Text> {
  
  @Override
  public void reduce(Text key, Iterable<Text> values, Context context)
      throws IOException, InterruptedException {
    
    for (IntWritable value : values) {
      context.write(key, value);
    }
  }
}
