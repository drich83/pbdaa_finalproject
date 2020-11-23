import java.io.IOException;

import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

public class NYPD_CleanMapper
    extends Mapper<LongWritable, Text, Text, Text> {

  private static final int MISSING = 9999;
  
  @Override
  public void map(LongWritable key, Text value, Context context)
      throws IOException, InterruptedException {
    
    String line = value.toString();
    String [] commaSplit = line.split(",");

    String result = "";

    int [] indexes = {0,1,2,11,13,15,21,32,33};

    if(commaSplit.length > 36){
      int diff = commaSplit.length - 36;
      indexes[6] += diff;
      indexes[7] += diff;
      indexes[8] += diff;    
    }

    if(commaSplit.length >= 36){
    for(int i = 0; i < indexes.length; i++){
      String current = commaSplit[indexes[i]];
      if(i == (indexes.length - 1)){
        result += current;
      }
      else{
        result += current + ",";
      }
    }
    }
    context.write(new Text(result), new Text(""));

  }
}
