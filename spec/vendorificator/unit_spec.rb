require_relative '../spec_helper'

module Vendorificator
  describe Unit do
    describe '#pushable_refs' do
      let(:environment) do
        Environment.new(Thor::Shell::Basic.new) do
          vendor :nginx, :group => :cookbooks
          vendor :nginx_simplecgi, :group => :cookbooks
        end
      end

      before do
        environment.git.capturing.stubs(:show_ref).returns <<EOF
a2745fdf2d7e51f139f9417c5ca045b389fa939f refs/heads/master
127eb134185e2bf34c79321819b81f8464392d45 refs/heads/vendor/cookbooks/nginx
0448bfa569d3d94dcb3e485c8da60fdb33d365f6 refs/heads/vendor/cookbooks/nginx_simplecgi
a2745fdf2d7e51f139f9417c5ca045b389fa939f refs/remotes/origin/master
127eb134185e2bf34c79321819b81f8464392d45 refs/remotes/origin/vendor/cookbooks/nginx
0448bfa569d3d94dcb3e485c8da60fdb33d365f6 refs/remotes/origin/vendor/cookbooks/nginx_simplecgi
e4646a83e6d24322958e1d7a2ed922dae034accd refs/tags/vendor/cookbooks/nginx/1.2.0
fa0293b914420f59f8eb4c347fb628dcb953aad3 refs/tags/vendor/cookbooks/nginx/1.3.0
680dee5e56a0d49ba2ae299bb82189b6f2660c9b refs/tags/vendor/cookbooks/nginx_simplecgi/0.1.0
EOF
        environment.load_vendorfile
      end

      it 'includes all own refs' do
        refs = environment['nginx'].pushable_refs
        assert { refs.include? 'refs/heads/vendor/cookbooks/nginx' }
        assert { refs.include? 'refs/tags/vendor/cookbooks/nginx/1.2.0' }
        assert { refs.include? 'refs/tags/vendor/cookbooks/nginx/1.3.0' }

        refs = environment['nginx_simplecgi'].pushable_refs
        assert { refs.include? 'refs/heads/vendor/cookbooks/nginx_simplecgi' }
        assert { refs.include? 'refs/tags/vendor/cookbooks/nginx_simplecgi/0.1.0' }
      end

      it "doesn't include other modules' refs" do
        refs = environment['nginx'].pushable_refs
        deny { refs.include? 'refs/tags/vendor/cookbooks/nginx_simplecgi/0.1.0' }
      end
    end
  end

  describe '#initialize' do
    it 'assigns to an overlay' do
      skip
    end
  end

end

