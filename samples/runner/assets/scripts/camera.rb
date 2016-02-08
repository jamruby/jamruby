java.import "android/hardware/Camera"
java.import "android/view/SurfaceView"
java.import "android/view/SurfaceHolder"

class MySurfaceHolderCallback < Android::View::SurfaceHolder::Callback.delegate
  attr_reader :camera

  def surfaceCreated(holder, *o)
    @camera = Android::Hardware::Camera.open # Add (1) for front camera
    @camera.preview_display = holder
    @camera.start_preview
  end

  def surfaceChanged(holder, format, width, height)
  end

  def surfaceDestroyed(holder, *o)
    @camera.stop_preview
    @camera.release
    @camera = nil
  end
end

class Main < JamRuby::Activity
  def on_create(bundle)
    @out_dir = "#{getExternalStorageDirectory}/jam_cam"
    Dir.mkdir(@out_dir) unless Dir.exist?(@out_dir)
  
    @surface_view = Android::View::SurfaceView.new(self)
    @surface_view.set_on_click_listener{|v| take_picture}
    
    @holder_callback = MySurfaceHolderCallback.new
    
    @surface_view.holder.add_callback @holder_callback
    
    ## Deprecated, but still required for older API version
    # @surface_view.holder.set_type Android::View::SurfaceHolder::SURFACE_TYPE_PUSH_BUFFERS
    
    setContentView @surface_view
  end

  def picture_id
    @picture_id ||= 0
    @picture_id += 1
  end

  def take_picture
    camera = @holder_callback.camera
    return unless camera

    picture_file = "#{@out_dir}/img_#{picture_id}.jpg"
    camera.take_picture(Android::Hardware::Camera::ShutterCallback.proxy {toast "Snap!"}, 
                        Android::Hardware::Camera::PictureCallback.proxy,
                        Android::Hardware::Camera::PictureCallback.proxy do |data, camera|
      begin 
        File.open(picture_file, "wb") do |f|
          f.write Base64.decode(data.encode64)
        end
        
        toast "Wrote to: #{picture_file}"
        
        @surface_view.postDelayed(JamRuby::Runnable.new do
          camera.startPreview
        end, 1000)  
      rescue => e
        toast "#{e}"
      end
    end)
  rescue => e
    toast "#{e}"
  end
end


