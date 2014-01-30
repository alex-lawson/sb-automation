function init(args)
    entity.setGravityEnabled(false)
    entity.setDamageOnTouch(false)
    entity.setDeathParticleBurst(entity.configParameter("deathParticles"))
    entity.setDeathSound(entity.randomizeParameter("deathNoise"))
    self.dead = false
end

function damage()
    self.dead = true
end
function shouldDie()
    return self.dead
end

function collide(args)
    entity.setVelocity({0,0})
    --entity.setAnimationState("movement", "idle")
end

function dig(args)
    entity.setVelocity({0,0})
    --entity.setAnimationState("movement", "idle")
end

function move(args)
    entity.setVelocity(args.velocity)
    entity.scaleGroup("chain", { 1, args.chain })
    --entity.setAnimationState("movement", "dig")
end

function burstParticleEmitter()
    if self.emitter then
        self.emitter = self.emitter - 1
        if self.emitter == 0 then
            entity.setParticleEmitterActive("dig", false)
            self.emitter = false
        end
    end
end